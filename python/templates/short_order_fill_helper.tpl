package com.euronext.optiq.integ.ddm;

import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

import com.euronext.optiq.dd.OrderSide_enum;
import com.euronext.optiq.dd.TradeLegSide_enum;
import com.euronext.optiq.dd.OrderEventType_enum;
import com.euronext.optiq.integ.ddm.iashorttrade.IAShortTrade;

import com.euronext.optiq.integ.common.IAOrderId;

import com.euronext.optiq.integ.ddm.iashorttrade.ShortTradeOrderIDSection;

{% for name, fld in shortTradeFields.iteritems() -%}
{% if fld.isGroup %}
import com.euronext.optiq.integ.ddm.iashorttrade.{{fld.type}};
{% endif -%}
{% endfor %}

public class IAShortOrderFillHelper {
    // suppress default constructor for noninstantiability
    private IAShortOrderFillHelper() {
        throw new AssertionError();
    }

    public static IAOrderId buildOrderId(final ShortTradeOrderIDSection orderIdSection) {
        return new IAOrderId(orderIdSection.getSymbolindex().getValue(),  orderIdSection.getOrderid().getValue());
    }

    public static ShortTradeOrderIDSection getOrderIdSection(final IAShortTrade shortTrade, final IAOrderId orderId) {
        final ShortTradeOrderIDSection orderIdSection1 = shortTrade.getShorttradeorderidsection().getValue().get(0);
        final ShortTradeOrderIDSection orderIdSection2 = shortTrade.getShorttradeorderidsection().getValue().get(1);

        final IAOrderId orderId1 = buildOrderId(orderIdSection1);
        final IAOrderId orderId2 = buildOrderId(orderIdSection2);

        if (orderId.equals(orderId1)) {
            return orderIdSection1;
        } else if (orderId.equals(orderId2)) {
            return orderIdSection2;
        } else {
            return null;
        }
    }

    public static ShortTradeOrderIDSection getOrderIdSection(final IAShortTrade shortTrade, final IALongOrder longOrder) {
        final IAOrderId orderId = new IAOrderId(longOrder.getSymbolindex().getValue(), longOrder.getOrderid().getValue());

        return getOrderIdSection(shortTrade, orderId);
    }

    public static ShortTradeOrderIDSection getOrderIdSection(final IAShortTrade shortTrade, final IAShortOrderFill shortOrder) {
        final IAOrderId orderId = new IAOrderId(shortOrder.getSymbolindex().getValue(), shortOrder.getOrderid().getValue());

        return getOrderIdSection(shortTrade, orderId);
    }

    public static ShortTradeOrderIDSection getOrderIdSection(final IAShortTrade shortTrade, int index) {
        return shortTrade.getShorttradeorderidsection().getValue().size() > index ? shortTrade.getShorttradeorderidsection().getValue().get(index) : null;
    }

    public static boolean getPullOrder(final IAShortTrade shortTrade, final IALongOrder longOrder) {
    {% if hasStrategyIACAFinishDC %}
        final ShortTradeOrderIDSection orderIdSection = getOrderIdSection(shortTrade, longOrder);

        if (orderIdSection != null) {
            return orderIdSection.getStrategyiacafinishdc().getValue().getPullorder();
        } else {
            // should not happens
            throw new IllegalArgumentException("The symbolIndex=" + 
                    longOrder.getSymbolindex().getValue() + 
                    " and orderId=" + longOrder.getOrderid().getValue() + 
                    " are not present in the shortTrade=" + shortTrade);
        }
    {% else %}
        return false;
    {% endif %}
    }

    public static boolean getNoOrderGeneration(final IAShortTrade shortTrade, final IALongOrder longOrder) {
    {% if hasStrategyIACAFinishDC %}
        final ShortTradeOrderIDSection orderIdSection = getOrderIdSection(shortTrade, longOrder);

        if (orderIdSection != null) {
            return orderIdSection.getStrategyiacafinishdc().getValue().getNoordergeneration();
        } else {
            // should not happens
            throw new IllegalArgumentException("The symbolIndex=" + 
                    longOrder.getSymbolindex().getValue() + 
                    " and orderId=" + longOrder.getOrderid().getValue() + 
                    " are not present in the shortTrade=" + shortTrade);
        }
    {% else %}
        return false;
    {% endif %}
    }

    {% for name, fld in shortTradeFields.iteritems() -%}
    {% if fld.isSet %}   
    private static {{fld.type}} clone{{fld.getCleanName()}}(final {{fld.type}} p) {
        final {{fld.type}} res  = new {{fld.type}}();

        {% for attr in fields_set[fld.type]  -%}
        res.set{{attr|title}}(p.get{{attr|title}}()); 
        {% endfor %}

        return res;
    }
    {% endif -%}
    {% endfor %}

    {% if 'strategyFieldsOrder1' and 'strategyFieldsOrder2' in shortTradeFields %}
    private static List<StrategyFields> getStrategyFieldsOrder2(List<StrategyFieldsOrder2> p) {
        final List<StrategyFields> res = new ArrayList<>();
        for (final StrategyFieldsOrder2 fields : p) {
            StrategyFields tmp = new StrategyFields();
            {% for fld in shortTradeFields['strategyFieldsOrder2'].fields -%}
            tmp.get{{fld.getCleanName()}}().setValue(fields.get{{fld.getCleanName()}}().getValue());
            {% endfor -%}
            res.add(tmp);
        }

        return res;
    }

    private static List<StrategyFields> getStrategyFieldsOrder1(List<StrategyFieldsOrder1> p) {
        final List<StrategyFields> res = new ArrayList<>();
        for (final StrategyFieldsOrder1 fields : p) {
            StrategyFields tmp = new StrategyFields();
            {% for fld in shortTradeFields['strategyFieldsOrder1'].fields -%}
            tmp.get{{fld.getCleanName()}}().setValue(fields.get{{fld.getCleanName()}}().getValue());
            {% endfor -%}
            res.add(tmp);
        }

        return res;
    }
    {% endif %}

    public static IAShortOrderFill shortTrade2Fill(final IAShortTrade shortTrade, int index) {

        final IAShortOrderFill shortOrder = new IAShortOrderFill();

        {% for name, fld in shortTradeFields.iteritems() -%}
        {% if fld.isGroup -%}

        {%- if fld.name == 'shortTradeOrderIDSection' %}
        final {{fld.type}} orderIdSection  = shortTrade.get{{fld.getCleanName()}}().getValue().get(index);
        {% elif fld.name == 'strategyFieldsOrder1' %}
        final List<{{fld.type}}> strategyFieldsOrder1  = shortTrade.get{{fld.getCleanName()}}().getValue();
        {% elif fld.name == 'strategyFieldsOrder2' %}
        final List<{{fld.type}}> strategyFieldsOrder2  = shortTrade.get{{fld.getCleanName()}}().getValue();
        {% endif %}

        {% elif fld.isSet and fld.name in orderFillFields -%}
        shortOrder.get{{fld.getCleanName()}}().setValue(clone{{fld.getCleanName()}}(shortTrade.get{{fld.getCleanName()}}().getValue()));
        {% elif fld.name in orderFillFields -%}
        shortOrder.get{{fld.getCleanName()}}().setValue(shortTrade.get{{fld.getCleanName()}}().getValue());
        {% endif -%}
        {% endfor %}


        {%- if 'strategyFieldsOrder1' and 'strategyFieldsOrder2' in shortTradeFields -%}
        if (index == 0) {
            shortOrder.getStrategyfields().setValue(getStrategyFieldsOrder1(strategyFieldsOrder1));
        } else {
            shortOrder.getStrategyfields().setValue(getStrategyFieldsOrder2(strategyFieldsOrder2));
        }
        {% endif -%}

        {# process orderIdSection fields#}
        {% for fld in shortTradeFields['shortTradeOrderIDSection'].fields -%}
        {% if fld.name in orderFillFields  -%}
        if (!orderIdSection.get{{fld.getCleanName()}}().isNull()) {
            shortOrder.get{{fld.getCleanName()}}().setValue(orderIdSection.get{{fld.getCleanName()}}().getValue());
        }
        {% endif -%}
        {% endfor %}

        // set missing fields not set dynamically
        shortOrder.getOrdereventtype().setValue(OrderEventType_enum.Fill);
        shortOrder.getBookouttime().setValue(shortTrade.getTradetime().getValue());
        shortOrder.getExecutionphase().setValue(shortTrade.getExecphase().getValue());

        // Cash/Deriv Compatibility - if tradeLegSide not null then use tradeLegSide
        final OrderSide_enum orderSide = orderIdSection.getTradelegside().getValue() != TradeLegSide_enum.NULL_VAL ?
                OrderSide_enum.get(orderIdSection.getTradelegside().getValue().value()) : orderIdSection.getOrderside().getValue();

        if (orderSide == OrderSide_enum.Sell) {
            if (shortTrade.getTradequalifier().getValue().getPassiveorder()) {
                shortOrder.getTradequalifier().getValue().setPassiveorder(false);
                shortOrder.getTradequalifier().getValue().setAggressiveorder(true);
            } else if (shortTrade.getTradequalifier().getValue().getAggressiveorder()) {
                shortOrder.getTradequalifier().getValue().setPassiveorder(true);
                shortOrder.getTradequalifier().getValue().setAggressiveorder(false);
            } 
        }

        // check if we received a quote fill ==> set quotesRep section
        if (orderIdSection.getQuoteindicator().getValue().shortValue() == 1) {
            final QuotesRep quotesRep = new QuotesRep();

            if (orderSide == OrderSide_enum.Buy) {
                quotesRep.getBidsize().setValue(orderIdSection.getOrderqty().getValue());
                quotesRep.getBidpx().setValue(orderIdSection.getOrderpx().getValue());
                quotesRep.getBidquotepriority().setValue(orderIdSection.getOrderpriority().getValue());
            } else {
                quotesRep.getOffersize().setValue(orderIdSection.getOrderqty().getValue());
                quotesRep.getOfferpx().setValue(orderIdSection.getOrderpx().getValue());
                quotesRep.getOfferquotepriority().setValue(orderIdSection.getOrderpriority().getValue());
            }

            shortOrder.getQuotesrep().setValue(Arrays.asList(quotesRep));
        }

        // set consume and produce time
        shortOrder.getConsumetime().setValue(shortTrade.getConsumetime().getValue());
        shortOrder.getProducetime().setValue(shortTrade.getProducetime().getValue());

        return shortOrder;
    }
}
