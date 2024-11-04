package com.euronext.optiq.integ.ddm;

{% for name, fld in tcsTradesPublicFields.iteritems() -%}
{% if fld.isGroup %}
import com.euronext.optiq.integ.ddm.tcstradespublic.{{fld.type}};
{% endif -%}
{% endfor %}

import com.euronext.optiq.integ.ddm.iametradedata.IAMETradeData;
import com.euronext.optiq.integ.ddm.tcstradespublic.TCSTradesPublic;

public class TCSTradesPublicBuilder {
    // suppress default constructor for noninstantiability
    private TCSTradesPublicBuilder() {
        throw new AssertionError();
    }

    public static TCSTradesPublic meTradeData2TCSTradesPublic(final IAMETradeData meTradeData) {
        final TCSTradesPublic tcsTrade = new TCSTradesPublic();

        {% for name, fld in meTradeDataFields.iteritems() -%}
        {% if name in tcsTradesPublicFields  -%}
            tcsTrade.get{{fld.getCleanName()}}().setValue(meTradeData.get{{fld.getCleanName()}}().getValue());
        {% endif -%}
        {% endfor %}
        return tcsTrade;
    }
}
