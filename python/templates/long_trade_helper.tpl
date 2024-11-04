package com.euronext.optiq.integ.ddm;

import com.euronext.optiq.integ.ddm.iashorttrade.IAShortTrade;

public class LongTradeHelper {
    // suppress default constructor for noninstantiability
    private LongTradeHelper() {
        throw new AssertionError();
    }

    public static void fillMainFields(final IALongTrade longTrade, final IAShortTrade shortTrade) {
        {% for fld in longTradeFields -%}
        {% if not fld.isGroup and fld.name in shortTradeFields -%}
        longTrade.get{{fld.getCleanName()}}().setValue(shortTrade.get{{fld.getCleanName()}}().getValue());
        {% endif -%}
        {% endfor %}
    }

    public static LongTradeOrderSection createOrderSection(final IALongOrder longOrder) {
        final LongTradeOrderSection section = new LongTradeOrderSection();

        {% for fld in longOrderFields -%}
        {% if fld.isGroup and fld.name in orderSectionFields -%}
        {% if fld.name not in ['strategyFields'] -%}
        if (longOrder.has{{fld.getCleanName()}}()) {
            final {{fld.type}} group = longOrder.get{{fld.getCleanName()}}().getValue().get(0);
            {% for subfld in fld.fields %}
            {%- if subfld.name in orderSectionFields -%}
            section.get{{subfld.getCleanName()}}().setValue(group.get{{subfld.getCleanName()}}().getValue());
            {% endif -%}
            {% endfor %}
        }
        {% endif -%}
        {%- elif fld.name in orderSectionFields  -%}
        section.get{{fld.getCleanName()}}().setValue(longOrder.get{{fld.getCleanName()}}().getValue());
        {% endif -%}
        {% endfor %}

        return section;
    }

}
