import os
from jinja2 import Environment, FileSystemLoader
import xml.etree.ElementTree as ET
from pprint import pprint
import sys

PATH = os.path.dirname(os.path.abspath(__file__))
TPL_ENV = Environment(
        autoescape=False,
        loader=FileSystemLoader(os.path.join(PATH, 'templates')),
        trim_blocks=False)

SHORT_ORDER_MESSAGES = {
        '12007' :   'IAOrderNewModify',
        '12008' :   'IAShortOrderFill',
        '12009' :   'IAShortOrderCancel',
        '12010' :   'IAShortOrderReject',
        '12011' :   'IAShortOrderTrigger',
        '12012' :   'IAShortOrderRefill',
        '12013' :   'IAShortOrderMTL',
        '12014' :   'IAShortOrderVFAVFC',
        '12015' :   'IAShortOrderConfirmation',
        '12016' :   'IAShortTradeCancellation',
        '12020' :   'IAShortOwnershipRequest',
        }


IACAFINISH_IACACOPY_MESSAGES = {
        '12050' :   'IAQuote',
        '12004' :   'IALongTrade',
        '12006' :   'IALongOrder',
        '12007' :   'IAOrderNewModify',
        '12008' :   'IAShortOrderFill',
        '12009' :   'IAShortOrderCancel',
        '12010' :   'IAShortOrderReject',
        '12011' :   'IAShortOrderTrigger',
        '12012' :   'IAShortOrderRefill',
        '12013' :   'IAShortOrderMTL',
        '12014' :   'IAShortOrderVFAVFC',
        '12015' :   'IAShortOrderConfirmation',
        '12016' :   'IAShortTradeCancellation',
        '12001' :   'IAMarketStatusChange',
        '12003' :   'IAPriceUpdate',
        '12020' :   'IAShortOwnershipRequest',
        '12021' :   'IATradeBustNotification',
        '12018' :   'IAStaticCollars',
        '12051' :   'IAAFQRFE',
        '12022' :   'IAQuoteRequest',
        '12902' :   'DropCopyFiltering',
        '542'   :   'DeclarationNoticeInternal',

        '16001' : 'DCMarketStatusChange',
        '16003' : 'DCPriceUpdate',
        '16006' : 'DCLongOrder',
        '16010' : 'DCShortOrderReject',
        '16016' : 'DCShortTradeCancellation',
        '16018' : 'DCStaticCollars',
        '16021' : 'DCTradeBustNotification',
        '16050' : 'DCQuote',
        '16060' :   'DCQuoteRequest',
        '16051' : 'DCAFQRFE'
        }

IACAFINISH_2_DROP_COPY_MESSAGES = {
        '12001' : {'id' : '16001', 'name' : 'DCMarketStatusChange'},
        '12003' : {'id' : '16003', 'name' : 'DCPriceUpdate'},
        '12006' : {'id' : '16006', 'name' : 'DCLongOrder'},
        '12010' : {'id' : '16010', 'name' : 'DCShortOrderReject'},
        '12016' : {'id' : '16016', 'name' : 'DCShortTradeCancellation'},
        '12018' : {'id' : '16018', 'name' : 'DCStaticCollars'},
        '12021' : {'id' : '16021', 'name' : 'DCTradeBustNotification'},
        '12050' : {'id' : '16050', 'name' : 'DCQuote'},
        '12022' : {'id' : '16060', 'name' : 'DCQuoteRequest'},
        '12051' : {'id' : '16051', 'name' : 'DCAFQRFE'}}

COMPOSITE_TYPE = 'composite';
SET_TYPE = 'set';

GEN_CODE_DIR = 'src/ddm/java/com/euronext/optiq/integ/ddm/'
TARGET_MARKET = sys.argv[1]

class Field:
    def __init__(self, fieldOrGroupNode, isField = True):
        if isField:
            self.fields = []
            self.name = fieldOrGroupNode.attrib['name']
            fieldType =  java_types[fieldOrGroupNode.attrib['type']]
            self.type = fieldType.javaType
            self.encodingType = fieldType.encodingType
            self.isEnum = ('_enum' in self.type)
            self.isSet = ('_set' in self.type)
            self.isGroup = False

            if 'presence' in fieldOrGroupNode.attrib:
                isOptional = (fieldOrGroupNode.attrib['presence'] == 'optional')
                if isOptional == True:
                    self.isRequired = 'false'
                else:
                    self.isRequired = 'true'
            else:
                self.isRequired = 'true'
        else:
            name = str(fieldOrGroupNode.attrib['name'])
            self.name = name[0].lower() + name[1:]
            self.type = name
            self.isEnum = False
            self.isSet = False
            self.isGroup = True
            self.isRequired = 'false'
            self.fields = []
            for child in fieldOrGroupNode:
                self.fields.append(Field(child))

        self.isProduceTime = self.name == 'produceTime'
        self.isConsumeTime = self.name == 'consumeTime'

    def getCleanName(self):
        return self.name.title()



class Group:
    def __init__(self, parentId, parentName, groupNode):
        self.parentId = parentId
        self.parentName = parentName
        self.groupNode = groupNode
        name = groupNode.attrib['name']
        self.name = name
        self.fullName = parentName + '_' + name

class FieldType:
    def __init__(self, javaType, encodingType=''):
        self.javaType = javaType
        self.encodingType = encodingType


def get_type(type):
    if type.tag == 'type':
        if type.attrib['name'] == 'unsigned_char':
            return FieldType('Short')
        elif type.attrib['name'] == 'int8_t':
            return FieldType('Byte');
        elif type.attrib['name'] == 'uint16_t':
            return FieldType('Integer')
        elif type.attrib['name'] == 'uint32_t':
            return FieldType('Long');
        elif type.attrib['name'] == 'uint64_t':
            return FieldType('Long');
        elif type.attrib['name'] == 'int32_t':
            return FieldType('Integer');
        elif type.attrib['name'] == 'int64_t':
            return FieldType('Long');
        elif type.attrib['name'] == 'time_t':
            return FieldType('Long');
        else:
            return FieldType('String');
    elif type.tag == 'enum':
        return FieldType(type.attrib['name'], type.attrib['encodingType'])
    elif type.tag == 'set':
        return FieldType(type.attrib['name'])
    else:
        return FieldType(COMPOSITE_TYPE)

def render_tpl(tpl_filename, context):
    return TPL_ENV.get_template(tpl_filename).render(context)

def gen_single_field(className, attrs):
    context = {'className' : className, 'attrs' : attrs}

    subDir = GEN_CODE_DIR

    # create subdirectory for field set classes
    if not os.path.exists(subDir):
        os.mkdir(subDir)

    fname = subDir + className + '.java'

    with open(fname, 'w') as f:
        content = render_tpl('field_set.tpl', context)
        f.write(content)

def gen_fields():
    for type_name, type in types.iteritems():
        if type.tag == 'set':
            attrs = []
            for choice in type:
                fld = str(choice.attrib['name'])
                fld = fld[0].lower() + fld[1:]
                attrs.append(fld)
            fields_set[type_name] = attrs
            gen_single_field(type.attrib['name'], attrs)


def gen_single_message(parentClassName, className, fields, isGroup = False, longOrderFields = {}, templateId = 0):
    both_messages = {}
    both_messages[templateId] = className

    isDcMsg = (templateId in IACAFINISH_2_DROP_COPY_MESSAGES)
    if isDcMsg:
        dcMessage = IACAFINISH_2_DROP_COPY_MESSAGES[templateId]
        both_messages[dcMessage['id']] = dcMessage['name']
    else:
        dcMessage = {'id' : 0, 'name' : ''}

    hasProduceTime = False
    hasConsumeTime = False
    fieldsByName = {}

    for field in fields:
        fieldsByName[field.name] = field
        if field.isProduceTime:
            hasProduceTime = True
        if field.isConsumeTime:
            hasConsumeTime = True

    isFinishMsg = (templateId in IACAFINISH_IACACOPY_MESSAGES)

    context = {
            'fieldsByMsgName' : message_fields,
            'parentClassName' : parentClassName,
            'className' : className,
            'templateId' : templateId,
            'isFinishMsg' : isFinishMsg,
            'hasProduceTime' : hasProduceTime,
            'hasConsumeTime' : hasConsumeTime,
            'fields' : fields,
            'fieldsByName' : fieldsByName,
            'dcMessage' : dcMessage,
            'both_messages' : both_messages,
            'longOrderFields' : longOrderFields,
            'countFields' : len(fields),
            'fields_set' : fields_set}

    if templateId not in IACAFINISH_IACACOPY_MESSAGES:
        if parentClassName != '':
            subDir = GEN_CODE_DIR + parentClassName.lower() + '/'
        else:
            subDir = GEN_CODE_DIR + className.lower() + '/'
    else:
        subDir = GEN_CODE_DIR

    # create subdirectory for classes
    if not os.path.exists(subDir):
        os.mkdir(subDir)

    # set output file name
    fname = subDir + className + '.java'

    if isGroup == True:
        content = render_tpl('group.tpl', context)
    elif templateId in SHORT_ORDER_MESSAGES:
        content = render_tpl('order_message.tpl', context)
    else:
        content = render_tpl('default_message.tpl', context)
    with open(fname, 'w') as f:
        f.write(content)

def gen_groups():
    for group_key, group in groups.iteritems():
        fields = []
        for child in group.groupNode:
            fields.append(Field(child))
        gen_single_message(group.parentName, group.name, fields, True, {}, group.parentId)


def gen_message_factory_class(context):
    # Generate message factory
    fname = GEN_CODE_DIR + 'MessageFactory.java'
    content = render_tpl('factory_message.tpl', context)
    with open(fname, 'w') as f:
        f.write(content)

def gen_long_trade_helper_class():
    longtrade = message_fields['IALongTrade']
    longorder = message_fields['IALongOrder']

    shortTradeFields = {}
    for fld in message_fields['IAShortTrade']:
        shortTradeFields[fld.name] = fld

    ordersection = {}
    for fld in longtrade:
        if fld.isGroup and fld.name == 'longTradeOrderSection':
            for subfld in fld.fields:
                ordersection[subfld.name] = subfld

    for fld in longorder:
        if fld.isGroup:
            for subfld in fld.fields:
                if subfld.name in ordersection:
                    ordersection[fld.name] = fld
    context = {
            'longOrderFields' : longorder,
            'longTradeFields' : longtrade,
            'shortTradeFields' : shortTradeFields,
            'orderSectionFields' : ordersection
            }

    fname = GEN_CODE_DIR + 'LongTradeHelper.java'
    content = render_tpl('long_trade_helper.tpl', context)
    with open(fname, 'w') as f:
        f.write(content)

def gen_short_order_fill_builder_class():
    shortTradeFields = {}
    for fld in message_fields['IAShortTrade']:
        shortTradeFields[fld.name] = fld

    orderFillFields =  {}
    for fld in message_fields['IAShortOrderFill']:
        orderFillFields[fld.name] = fld

    hasStrategyIACAFinishDC = False
    for fld in shortTradeFields['shortTradeOrderIDSection'].fields:
        if fld.name == 'strategyIACAFinishDC':
            hasStrategyIACAFinishDC = True
            break

    context = {
            'shortTradeFields' : shortTradeFields,
            'orderFillFields' : orderFillFields,
            'hasStrategyIACAFinishDC': hasStrategyIACAFinishDC,
            'fields_set': fields_set
            }

    fname = GEN_CODE_DIR + 'IAShortOrderFillHelper.java'
    content = render_tpl('short_order_fill_helper.tpl', context)
    with open(fname, 'w') as f:
        f.write(content)

def gen_tcs_trades_public_builder_class():
    meTradeDataFields =  {}
    for fld in message_fields['IAMETradeData']:
        meTradeDataFields[fld.name] = fld

    tcsTradesPublicFields =  {}
    for fld in message_fields['TCSTradesPublic']:
        tcsTradesPublicFields[fld.name] = fld

    context = {
            'tcsTradesPublicFields' : tcsTradesPublicFields,
            'meTradeDataFields' : meTradeDataFields
            }
    fname = GEN_CODE_DIR + 'TCSTradesPublicBuilder.java'
    content = render_tpl('tcs_trades_public_builder.tpl', context)
    with open(fname, 'w') as f:
        f.write(content)

def gen_messages(root):
    longorder_fields = {}
    message_ids = {}

    for message_name, message in messages.iteritems():
        fields = []
        for child in message:
            if child.tag == 'field':
                fld = Field(child, True)
            else:
                fld = Field(child, False)

            fields.append(fld)
            if message_name == 'IALongOrder':
                longorder_fields[fld.name] = fld

        message_fields[message_name] = fields
        message_ids[message_name] = message.attrib['id']

    for message_name, fields in message_fields.iteritems():
        gen_single_message('', message_name, fields, False, longorder_fields, message_ids[message_name])


    semanticVersion = root.attrib['semanticVersion']
    print "DMM Version :", semanticVersion

    context = {
            'messages' : messages,
            'semanticVersion' : semanticVersion,
            'finish_copy_messages' : IACAFINISH_IACACOPY_MESSAGES
            }

    # Generate message factory
    gen_message_factory_class(context)

    # Generate long trade helper
    gen_long_trade_helper_class()

    # Generate short order fill builder
    gen_short_order_fill_builder_class()

    # Generate tcs trades public builder
    gen_tcs_trades_public_builder_class()

def gen_classes(root):
    gen_fields()
    gen_groups()
    gen_messages(root)

types = {}
fields_set = {}
messages = {}
message_fields = {}
groups = {}
java_types = {}

java_types['char'] = FieldType('Byte')

def main():

    os.system("xmllint --schema optiq-dd-ref/dd.xsd optiq-dd-ref/dd.xml --noout")
    os.system("xsltproc --stringparam target %s -o src/main/resources/tree.xml optiq-dd-gen/xsl/tree.xsl optiq-dd-ref/dd.xml" %(TARGET_MARKET))
    os.system("xsltproc --param allEnumsAndSets 0 -o src/main/resources/sbe_input_without_id.xml optiq-dd-gen/xsl/sbe_input_without_id.xsl src/main/resources/tree.xml")
    os.system("xsltproc --param allEnumsAndSets 0 -o src/main/resources/sbe_input.xml optiq-dd-gen/xsl/sbe_input_with_id.xsl src/main/resources/sbe_input_without_id.xml")

    tree = ET.parse('src/main/resources/sbe_input.xml')
    root = tree.getroot()

    for child in root:
        if child.tag == 'types':
            for child2 in child:
                types[child2.attrib['name']] = child2
                java_types[child2.attrib['name']] = get_type(child2)
        elif 'message' in child.tag:
            messages[child.attrib['name']] = child
            for child2 in child:
                if child2.tag == 'group':
                    group =  Group(child.attrib['id'], child.attrib['name'], child2);
                    groups[group.fullName] = group


    # create top directory for generated classes
    if not os.path.exists(GEN_CODE_DIR):
        os.makedirs(GEN_CODE_DIR)

    # generate classes
    gen_classes(root);

    print "Classes generated successfully."

if __name__== "__main__":
    main()

