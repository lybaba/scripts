// Created by scripts/generate.py, please don't edit manually.
package com.euronext.optiq.integ.ddm;
import java.util.HashMap;

import com.euronext.optiq.integ.common.IAMessage;
import com.euronext.optiq.integ.common.JsonMessage;
import com.euronext.optiq.sbe.serdes.SbeRawMessage;

{% for messageName, message in messages.iteritems() %}
{% if message.attrib['id'] not in finish_copy_messages -%}
import com.euronext.optiq.integ.ddm.{{messageName|lower}}.{{messageName}};
{%- endif -%}
{%- endfor %}

public class MessageFactory {
    public static final String ddmVersion  = "{{semanticVersion}}";

    /**
     * Convert json message to ia message
     * @param jsonMessage a given ddm message in json format
     * 
     */
    public static IAMessage json2IAMessage(final JsonMessage jsonMessage) {
        final IAMessage iaMessage = newIAMessage(jsonMessage.getTemplateId());
        if (iaMessage != null) {
            iaMessage.set(jsonMessage);
        }

        return iaMessage;
    }

    /**
     * Convert sbe raw message to ia message
     * @param sbeRawMessage a given sbe raw message
     * 
     */
    public static IAMessage sbe2IAMessage(SbeRawMessage sbeRawMessage) {
        final IAMessage iaMessage = newIAMessage(sbeRawMessage.getTemplateId());
        if (iaMessage != null) {
            iaMessage.set(sbeRawMessage);
        }

        return iaMessage;
    }

    /**
     * Create a new ia message
     * @param templateId
     * 
     */
    public static IAMessage newIAMessage(int templateId) {
        switch (templateId) {
        {% for messageName, message in messages.iteritems() %}
        case {{message.attrib['id']}}:
            return new {{messageName}}();
        {%- endfor %}
        }

        return null;
    }

    /**
     * Convert sbe raw message to string
     * @param sbeRawMessage a given sbe raw message
     * 
     */
    public static String sbe2Str(SbeRawMessage sbeRawMessage) {
        String str = null;
        switch (sbeRawMessage.getTemplateId()) {
            {% for messageName, message in messages.iteritems() %}
            case {{message.attrib['id']}}:
            {
                {{messageName}} msg = new {{messageName}}(sbeRawMessage);
                str = msg.getEncodedMessage().toString();
            }
            break;
            {%- endfor %}
        }

        return str;
    }
}
