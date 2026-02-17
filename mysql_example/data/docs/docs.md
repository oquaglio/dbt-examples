{% docs order_status %}

The status of an order. One of:

| Status      | Description                          |
|-------------|--------------------------------------|
| pending     | Order placed but not yet fulfilled   |
| completed   | Order successfully delivered         |
| returned    | Order was returned by the customer   |

{% enddocs %}

{% docs amount_dollars %}

The order amount converted from cents to dollars using the `cents_to_dollars` macro.

{% enddocs %}
