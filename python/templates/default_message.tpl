// Created by scripts/generate.py, please don't edit manually.
{% if isFinishMsg %}
package com.euronext.optiq.integ.ddm;
{% else %}
package com.euronext.optiq.integ.ddm.{{className|lower}};
{% endif %}
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.math.NumberUtils;
import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;

import java.nio.ByteBuffer;
import org.agrona.concurrent.UnsafeBuffer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.euronext.optiq.dd.MessageHeaderEncoder;
import com.euronext.optiq.dd.{{className}}Decoder;

{% for tplId, msgName in both_messages.iteritems() %}
import com.euronext.optiq.dd.{{msgName}}Encoder;
{% endfor %}
import com.euronext.optiq.sbe.serdes.SbeRawMessage;
{# import enum declarations #}
{%- for fld in fields -%}
{% if fld.isEnum %}
import com.euronext.optiq.dd.{{fld.type}};
{%- endif %}
{%- endfor %}

{# import field set declarations #}
{%- for fld in fields -%}
{% if fld.isSet %}
import com.euronext.optiq.integ.ddm.{{fld.type}};
{%- endif %}
{%- for subfld in fld.fields -%}
{% if subfld.isSet %}
import com.euronext.optiq.integ.ddm.{{subfld.type}};
{%- endif %}
{%- endfor %}
{%- endfor %}

import com.euronext.optiq.integ.common.IAFieldType_enum;
import com.euronext.optiq.integ.common.IAFieldT;
import com.euronext.optiq.integ.common.IAMessage;
import com.euronext.optiq.integ.common.JsonMessage;
import com.euronext.optiq.integ.common.TimeUtils;

public class {{className}} extends IAMessage {
    private static Logger logger = LoggerFactory.getLogger({{className}}.class);
    private static final int MAX_BUFFER_CAPACITY = 4 * 1024;
    private static MessageHeaderEncoder messageHeaderEncoder = new MessageHeaderEncoder(); 

    {% for fld in fields %}
    {% if fld.isGroup %}
    private IAFieldT<List<{{fld.type}}>> {{fld.name}};
    {% else %}
    private IAFieldT<{{fld.type}}> {{fld.name}};
    {% endif %}
    {%- endfor %}

    public static int countFields() {
        return {{countFields}};
    }

    /**
    * Default Constructor
    */
    public {{className}}() {
        super({{className}}Decoder.TEMPLATE_ID);
        init();
    }

    /**
    *  Constructor
    * @param sbeRawMessage a given sbe raw message
    */
    public {{className}}(SbeRawMessage sbeRawMessage) {
        super({{className}}Decoder.TEMPLATE_ID);
        init();
        set(sbeRawMessage);
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == null) { return false; }
        if (obj == this) { return true; }
        if (obj.getClass() != getClass()) {
            return false;
        }

        @SuppressWarnings("unchecked")
        {{className}} rhs = ({{className}}) obj;

        return new EqualsBuilder()
            {% for fld in fields %}
            {% if fld.name not in ['produceTime', 'consumeTime'] -%}
            .append({{fld.name}}, rhs.{{fld.name}})
            {%- endif -%}
            {%- endfor %}
            .isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37)
            {% for fld in fields %}
            {% if fld.name not in ['produceTime', 'consumeTime'] -%}
            .append({{fld.name}})
            {%- endif -%}
            {%- endfor %}
            .toHashCode();
    }

    /**
    * Init fiels
    */
    private void init() {
        {% for fld in fields %}
        {% if fld.type == 'String' %}
        {{fld.name}} = new IAFieldT<{{fld.type}}>(IAFieldType_enum.StringType, "{{fld.name}}", null, {{fld.isRequired}});
        {%- elif fld.isSet %}
        {{fld.name}} = new IAFieldT<{{fld.type}}>(IAFieldType_enum.SetType, "{{fld.name}}", new {{fld.type}}(), {{fld.isRequired}});
        {%- elif fld.isEnum %}
        {{fld.name}} = new IAFieldT<{{fld.type}}>(IAFieldType_enum.EnumType, "{{fld.name}}", {{fld.type}}.NULL_VAL, {{fld.isRequired}});
        {%- elif fld.isGroup %}
        {{fld.name}} = new IAFieldT<List<{{fld.type}}>>(IAFieldType_enum.GroupType, "{{fld.name}}", new ArrayList<{{fld.type}}>(), {{fld.isRequired}});
        {%- else %}
        {{fld.name}} = new IAFieldT<{{fld.type}}>(IAFieldType_enum.{{fld.type}}Type, "{{fld.name}}", {{className}}Decoder.{{fld.name}}NullValue(), {{fld.isRequired}});
        {%- endif %}
        getFields().put("{{fld.name}}", {{fld.name}});
        {%- endfor %}
    }

    /**
    * Reset fiels
    */
    public void reset() {
        {% for fld in fields %}
        {{fld.name}}.reset();
        {%- endfor %}
    }


    private ByteBuffer getOrCreateByteBuffer() {
        return ByteBuffer.allocate(MAX_BUFFER_CAPACITY);
    }

    /**
     * Get modified sbe raw message
     * @return sbeRawMessage
     */
    @Override
    public SbeRawMessage getModifiedSbeRawMessage() {
        final ByteBuffer byteBuffer = getOrCreateByteBuffer();
        {{className}}Encoder enc = doGetEncodedMessage{{templateId}}(byteBuffer);
		
        byte[] bytes = new byte[byteBuffer.limit()];
        byteBuffer.get(bytes);

        return new SbeRawMessage(
                enc.sbeTemplateId(),
                enc.sbeSchemaId(),
                enc.sbeSchemaVersion(),
                enc.sbeBlockLength(),
                messageHeaderEncoder.encodedLength(),
                bytes); 
    }

    {% if dcMessage['id'] %}
    /**
     * Get drop copy modified sbe raw message
     * @return sbeRawMessage
     */
    @Override
    public SbeRawMessage getDCModifiedSbeRawMessage() {
        final ByteBuffer byteBuffer = getOrCreateByteBuffer();
        {{dcMessage['name']}}Encoder enc = doGetEncodedMessage{{dcMessage['id']}}(byteBuffer);
		
        byte[] bytes = new byte[byteBuffer.limit()];
        byteBuffer.get(bytes);

        return new SbeRawMessage(
                enc.sbeTemplateId(),
                enc.sbeSchemaId(),
                enc.sbeSchemaVersion(),
                messageHeaderEncoder.encodedLength(),
                messageHeaderEncoder.encodedLength(),
                bytes); 
    }
    {% endif %}

    /**
     * Get modified sbe decoder
     * @return Decoder
     */
    public {{className}}Decoder getDecoder() {
        final SbeRawMessage modifiedMsg = getModifiedSbeRawMessage();
        {{className}}Decoder dec = new {{className}}Decoder();

        final UnsafeBuffer directBuffer = new UnsafeBuffer(modifiedMsg.getRawData());
        final int actingVersion = modifiedMsg.getActingVersion();

        dec.wrap(directBuffer, modifiedMsg.getMessageOffset(), modifiedMsg.getBlockLength(), actingVersion);

        return dec;
    }

    /**
     * Get modified sbe raw message
     * @return sbeRawMessage
     */
    public {{className}}Encoder getEncodedMessage() {
        final ByteBuffer byteBuffer = getOrCreateByteBuffer();
        return doGetEncodedMessage{{templateId}}(byteBuffer);
    }

    {% for tplId, msgName in both_messages.iteritems() %}
    /**
     * Get modified sbe raw message
     * @param byteBuffer
     * @return sbeRawMessage
     */
     public {{msgName}}Encoder doGetEncodedMessage{{tplId}}(final ByteBuffer byteBuffer) {
        {% if hasProduceTime %}
        // set produce time
        getProducetime().setValue(TimeUtils.getNanoSecondsSinceEpoch());
        {% endif %}

        {{msgName}}Encoder enc = new {{msgName}}Encoder();
        final UnsafeBuffer directBuffer = new UnsafeBuffer(byteBuffer);
        int bufferOffset = 0;       

        messageHeaderEncoder
            .wrap(directBuffer, bufferOffset)
            .blockLength(enc.sbeBlockLength())
            .templateId(enc.sbeTemplateId())
            .schemaId(enc.sbeSchemaId())
            .version(enc.sbeSchemaVersion());

        bufferOffset += messageHeaderEncoder.encodedLength(); 

        enc.wrap(directBuffer, bufferOffset);

        {% for fld in fieldsByMsgName[msgName] -%}
        {% if fld.name in fieldsByName -%}
        {% if fld.isSet %}
        enc.{{fld.name}}().clear();
        if (get{{fld.getCleanName()}}().getValue() != null) {
            {% for attr in fields_set[fld.type] %}
            enc.{{fld.name}}().{{attr}}(get{{fld.getCleanName()}}().getValue().get{{attr|title}}());
            {% endfor %}
        }
        {% elif fld.isGroup %}
        if (has{{fld.getCleanName()}}()) {
            {{msgName}}Encoder.{{fld.type}}Encoder subEnc =
                enc.{{fld.name}}Count(get{{fld.getCleanName()}}().getValue().size());
            for ({{fld.type}} repItem : get{{fld.getCleanName()}}().getValue()) {
                subEnc.next();
                {% for subfld in fld.fields -%}
                {% if subfld.isSet %}
                subEnc.{{subfld.name}}().clear();
                {% for attr in fields_set[subfld.type] -%}
                subEnc.{{subfld.name}}().{{attr}}(repItem.get{{subfld.getCleanName()}}().getValue().get{{attr|title}}());
                {% endfor %}
                {% else %}
                {% if subfld.type == 'String' %}
                if (repItem.get{{subfld.getCleanName()}}().getValue() != null) {
                    subEnc.{{subfld.name}}(repItem.get{{subfld.getCleanName()}}().getValue());
                } else {
                    subEnc.{{subfld.name}}("");
                }
                {% else %}
                subEnc.{{subfld.name}}(repItem.get{{subfld.getCleanName()}}().getValue());
                {% endif %}
                {% endif %}
                {%- endfor %}
            }
        } else {
            enc.{{fld.name}}Count(0);
        }
        {% elif fld.type == 'String' %}
        if (get{{fld.getCleanName()}}().getValue() != null) {
            enc.{{fld.name}}(get{{fld.getCleanName()}}().getValue());
        } else {
            enc.{{fld.name}}("");
        }
        {% else %}
        enc.{{fld.name}}(get{{fld.getCleanName()}}().getValue());
        {% endif %}
        {% else %}
        // field {{fld.name}} not found
        {% endif -%}
        {%- endfor %}

        byteBuffer.limit(messageHeaderEncoder.encodedLength() + enc.encodedLength());
        
        return enc;
    }
    {%- endfor %}

    /**
     * Set this message fields with a {{className}} Sbe Raw Message
     * @param sbeRawMessage the {{className}} Sbe Raw Message
     */
    public void set(SbeRawMessage sbeRawMessage) {
        {{className}}Decoder dec = new {{className}}Decoder();

        if (sbeRawMessage == null) {
            logger.error("SbeRawMessage is null");
            return;
        }

        if (sbeRawMessage.getTemplateId() != {{className}}Decoder.TEMPLATE_ID) {
            logger.error("message is not an {{className}}, templateId = " + sbeRawMessage.getTemplateId());
            throw new IllegalStateException("Template ids do not match");
        }

        final UnsafeBuffer directBuffer = new UnsafeBuffer(sbeRawMessage.getRawData());

        final int actingVersion = sbeRawMessage.getActingVersion();

        dec.wrap(directBuffer, sbeRawMessage.getMessageOffset(), sbeRawMessage.getBlockLength(), actingVersion);

        {% for fld in fields -%}
        {% if fld.isSet %}
        get{{fld.getCleanName()}}().setValue(new {{fld.type}}(dec.{{fld.name}}()));
        {% elif fld.isGroup %}
        {
            {{className}}Decoder.{{fld.type}}Decoder subDec = dec.{{fld.name}}();
            if (subDec.count() > 0) {
                List<{{fld.type}}> listRep = new ArrayList<{{fld.type}}>();
                while (subDec.hasNext()) {
                    subDec.next();

                    {{fld.type}} grp = new {{fld.type}}();
                    {% for subfld in fld.fields -%}
                    {% if subfld.isSet %}
                    grp.get{{subfld.getCleanName()}}().setValue(new {{subfld.type}}(subDec.{{subfld.name}}()));
                    {% else %}
                    grp.get{{subfld.getCleanName()}}().setValue(subDec.{{subfld.name}}());
                    {% endif %}
                    {%- endfor %}
                    listRep.add(grp);
                }
                get{{fld.getCleanName()}}().setValue(listRep);
            } else {
                get{{fld.getCleanName()}}().reset();
            }
        }
        {% else %}

        {% if fld.getCleanName() == 'Producetime' -%}
        setOriginalProduceTime(dec.{{fld.name}}());
        {% elif fld.getCleanName() == 'Consumetime' -%}
        setOriginalConsumeTime(dec.{{fld.name}}());
        {% endif -%}

        get{{fld.getCleanName()}}().setValue(dec.{{fld.name}}());
        {% endif %}
        {%- endfor %}

        {% if hasConsumeTime %}
        // set consume time
        getConsumetime().setValue(sbeRawMessage.getRcvdTms());
        {% endif %}
    }

    {% for fld in fields %}
    {% if fld.isGroup -%}
    public IAFieldT<List<{{fld.type}}>> get{{fld.getCleanName()}}() {
        return this.{{fld.name}};
    }
    public boolean has{{fld.getCleanName()}}() {
        return this.{{fld.name}}.getValue() != null
               && this.{{fld.name}}.getValue().size() > 0;
    }
    public boolean has{{fld.getCleanName()}}(int index) {
        return this.{{fld.name}}.getValue() != null
               && this.{{fld.name}}.getValue().size() > index;
    }
    {% else %}
    public IAFieldT<{{fld.type}}> get{{fld.getCleanName()}}() {
        return this.{{fld.name}};
    }
    {% endif %}
    {% endfor %}

    {% for fld in fields %}
    {% if (fld.isGroup) %}
    /**
     * Set the field value from a str
     * @param keyValMap the new values to set where
     * the key is the field name and the val the field value
    */
    private void set{{fld.getCleanName()}}(final Map<String, String> keyValMap) {
        {{fld.type}}.fromStr(get{{fld.getCleanName()}}(), keyValMap);
    }
    /**
     * Set the field value from a str
     * @param keyValMap the new values to set where
     * the key is the field name and the val the field value
    */
    private void jsonSet{{fld.getCleanName()}}(final Map<String, Object> keyValMap) {
        {{fld.type}}.fromJsonStr(get{{fld.getCleanName()}}(), keyValMap);
    }
    {% elif not fld.isSet %}
    /**
     * Set the field value from a str
     * @param val the new value to set
    */
    private void set{{fld.getCleanName()}}(final String val) {
        {% if fld.type == 'String' -%} 
        this.{{fld.name}}.setValue(val);
        {%- elif fld.type == 'Integer' -%}
        this.{{fld.name}}.setValue(Integer.parseInt(val));
        {%- elif fld.type == 'Long' -%}
        this.{{fld.name}}.setValue(Long.parseLong(val));
        {%- elif fld.type == 'Short' -%}
        this.{{fld.name}}.setValue(Short.parseShort(val));
        {%- elif fld.isEnum -%}
        if (NumberUtils.isDigits(val)) {
            {% if fld.encodingType == 'char' -%} 
            this.{{fld.name}}.setValue({{fld.type}}.get(Byte.parseByte(val)));
            {%- else -%}
            this.{{fld.name}}.setValue({{fld.type}}.get(Short.parseShort(val)));
            {%- endif -%}
        } else {
            this.{{fld.name}}.setValue({{fld.type}}.valueOf(val));
        }
        {% endif %}
    }
    {% endif %}
    {% endfor %}


    /**
     * Set with a json  message
     * @param JsonMessage a given json message
     * 
     */
    @Override
    public void set(JsonMessage jsonMessage) {
        {% for fld in fields %}
        {% if (fld.isSet) %}
        // {{fld.name}}
        {
            final Map<String, String> map  = (Map<String, String>)jsonMessage.getMainFields().get("{{fld.name|lower}}");
            if (map != null) {
                {{fld.name}}.getValue().fromStr(map);
            }
        }
        {% elif (fld.isGroup) %}
        // {{fld.name}}
        {
            final  List<Map<String, Object>> fieldsList =
                jsonMessage.getRepGroupFieldsListMap().get("{{fld.name|lower}}");
            if (fieldsList != null) {
                for (final Map<String, Object> map : fieldsList) {
                    jsonSet{{fld.getCleanName()}}(map);
                }
            }
        }
        {% else %}
        // {{fld.name}}
        {
            final String val = (String)jsonMessage.getMainFields().get("{{fld.name|lower}}");
            if (val != null) {
                set{{fld.getCleanName()}}(val);
            }
        }
        {% endif %}
        {%- endfor %}
    }
}
