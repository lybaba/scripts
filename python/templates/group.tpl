// Created by scripts/generate.py, please don't edit manually.
{% if isFinishMsg %}
package com.euronext.optiq.integ.ddm;
{% else %}
package com.euronext.optiq.integ.ddm.{{parentClassName|lower}};
{% endif %}
import java.util.ArrayList;
import java.util.Map;
import java.util.Arrays;
import java.util.List;
import org.apache.commons.lang3.math.NumberUtils;
import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;

import com.euronext.optiq.dd.{{parentClassName}}Decoder;
{# import enum declarations #}
{% for fld in fields -%}
{% if fld.isEnum %}
import com.euronext.optiq.dd.{{fld.type}};
{%- endif %}
{%- endfor %}

{# import field set declarations #}
{%- for fld in fields -%}
{% if fld.isSet %}
import com.euronext.optiq.integ.ddm.{{fld.type}};
{%- endif %}
{%- endfor %}

import com.euronext.optiq.integ.common.IAFieldType_enum;
import com.euronext.optiq.integ.common.IAFieldT;

public class {{className}} {
    {% for fld in fields %}
    private IAFieldT<{{fld.type}}> {{fld.name}};
    {%- endfor %}

    @SuppressWarnings("serial")
    static final ArrayList<String> fields = new ArrayList<String>() {% raw %}{{{% endraw -%} 
        {% for fld in fields %}
        add("{{fld.name}}");
        {%- endfor %}
    {% raw %}}}{% endraw %};

    public static int countFields() {
        return {{countFields}};
    }

    /**
    * Default Constructor
    */
    public {{className}}() {
        {% for fld in fields %}
        {% if fld.type == 'String' -%}
        this.{{fld.name}} = new IAFieldT<{{fld.type}}>(IAFieldType_enum.StringType, "{{fld.name}}", null, {{fld.isRequired}}, {{loop.index}});
        {%- elif fld.isSet -%}
        this.{{fld.name}} = new IAFieldT<{{fld.type}}>(IAFieldType_enum.SetType, "{{fld.name}}", new {{fld.type}}(), {{fld.isRequired}}, {{loop.index}});
        {%- elif fld.isEnum -%}
        this.{{fld.name}} = new IAFieldT<{{fld.type}}>(IAFieldType_enum.EnumType, "{{fld.name}}", {{fld.type}}.NULL_VAL, {{fld.isRequired}}, {{loop.index}});
        {%- else -%}
        this.{{fld.name}} = new IAFieldT<{{fld.type}}>(IAFieldType_enum.{{fld.type}}Type, "{{fld.name}}", {{parentClassName}}Decoder.{{className}}Decoder.{{fld.name}}NullValue(), {{fld.isRequired}}, {{loop.index}});
        {%- endif %}
        {%- endfor %}
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
            .append({{fld.name}}, rhs.{{fld.name}})
            {%- endfor %}
            .isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37)
            {% for fld in fields %}
            .append({{fld.name}})
            {%- endfor %}
            .toHashCode();
    }

    {% for fld in fields %}
    public IAFieldT<{{fld.type}}> get{{fld.getCleanName()}}() {
        return this.{{fld.name}};
    }
    {% endfor %}

    {% for fld in fields %}
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
        {%- elif fld.isSet -%}
        List<String> items = Arrays.asList(val.split("\\s*,\\s*"));
        this.{{fld.name}}.getValue().fromStr(items);
        {%- else -%}
        // implementme
        {% endif %}
    }
    {% endfor %}

    /**
     * Set the field obj from a str
     * @param obj the field to set
     * @param keyValMap the new values to set where
     * the key is the field name and the val the field value
    */
    public static void fromStr(IAFieldT<List<{{className}}>> obj, final Map<String, String> keyValMap) {
        {{className}} group = new {{className}}();
        {% for fld in fields %}
        {
            final String val = keyValMap.get("{{fld.name|lower}}");
            if (val != null) {
                group.set{{fld.getCleanName()}}(val);
            }
        }
        {%- endfor %}

        obj.getValue().add(group);
    }

    /**
     * Set the field obj from a json str
     * @param obj the field to set
     * @param keyValMap the new values to set where
     * the key is the field name and the val the field value
    */
    public static void fromJsonStr(IAFieldT<List<{{className}}>> obj, final Map<String, Object> keyValMap) {
        {{className}} group = new {{className}}();
        {% for fld in fields %}
        {% if (fld.isSet) %}
        // {{fld.name}}
        {
            final Map<String, String> map  = (Map<String, String>)keyValMap.get("{{fld.name|lower}}");
            if (map != null) {
                group.get{{fld.getCleanName()}}().getValue().fromStr(map);
            }
        }
        {% else %}
        // {{fld.name}}
        {
            final String val = (String)keyValMap.get("{{fld.name|lower}}");
            if (val != null) {
                group.set{{fld.getCleanName()}}(val);
            }
        }
        {% endif %}
        {%- endfor %}

        obj.getValue().add(group);
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        
        {% for fld in fields -%}
        sb.append("\"")
        .append("{{fld.name}}")
        .append("\"")
        .append(": ")
        .append({{fld.name}}.toString());
        {% if loop.index < loop.length %}
        sb.append(",");
        {% endif -%}
        {%- endfor %}

        sb.append("}");

        return sb.toString();
    }
}
