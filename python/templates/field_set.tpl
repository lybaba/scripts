// Created by scripts/generate.py, please don't edit manually.
package com.euronext.optiq.integ.ddm;

import java.util.Map;
import java.util.List;

import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;

import com.euronext.optiq.dd.{{className}}Decoder;
import com.euronext.optiq.integ.common.IAFieldType_enum;
import com.euronext.optiq.integ.common.IAFieldT;

public class {{className}} {
    {% for attr in attrs %}
    private IAFieldT<Boolean> {{attr}};
    {% endfor %}

    /**
     * Default Constructor
     */
    public {{className}}()
    {
        {% for attr in attrs %}
        this.{{attr}} = new IAFieldT<Boolean>(IAFieldType_enum.BooleanType, "{{attr}}", false, false, {{loop.index}});
        {% endfor %}
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
            {% for attr in attrs %}
            .append({{attr}}, rhs.{{attr}})
            {%- endfor %}
            .isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37)
            {% for attr in attrs %}
            .append({{attr}})
            {%- endfor %}
            .toHashCode();
    }

    /**
     * Constructor
     * @param dec
     */
    public {{className}}({{className}}Decoder dec)
    {
        {% for attr in attrs %}
        this.{{attr}} = new IAFieldT<Boolean>(IAFieldType_enum.BooleanType, "{{attr}}", false, false, {{loop.index}});
        if (dec != null) {
            this.{{attr}}.setValue(dec.{{attr}}());
        }
        {% endfor %}
    }

    {% for attr in attrs %}
    public void set{{attr|title}}(boolean {{attr}}) {
        this.{{attr}}.setValue({{attr}});
    }

    public boolean get{{attr|title}}() {
        return this.{{attr}}.getValue();
    }
    {% endfor %}

    /**
     * Set the field value from a list of strings
     * @param items the new items to set
    */
    public void fromStr(final List<String> items) {
        {% for attr in attrs %}
        if (items.contains("{{attr}}")) {
            this.{{attr}}.setValue(true);
        }
        {% endfor %}
    }

    {% for attr in attrs %}
    /**
     * Set the field value from a str
     * @param val the new value to set
    */
    private void set{{attr|title}}(final String val) {
        this.{{attr}}.setValue(Boolean.parseBoolean(val));
    }

    {% endfor %}

    /**
     * Set the field obj from a str
     * @param keyValMap the new values to set where
     * the key is the field name and the val the field value
    */
    public void fromStr(final Map<String, String> keyValMap) {
        {% for attr in attrs %}
        {
            final String val = keyValMap.get("{{attr|lower}}");
            if (val != null) {
                if (val.equals("true")) {
                    this.{{attr}}.setValue(true);
                } else if (val.equals("false")) {
                    this.{{attr}}.setValue(false);
                }
            }
        }
        {%- endfor %}
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        
        {% for attr in attrs -%}
        sb.append("\"")
        .append("{{attr}}")
        .append("\"")
        .append(": ")
        .append({{attr}}.toString());
        {% if loop.index < loop.length %}
            sb.append(",");
        {% endif -%}
        {%- endfor %}

        sb.append("}");

        return sb.toString();
    }
}
