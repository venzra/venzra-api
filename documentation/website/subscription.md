## Subscription

This section gives access to information about subscriptions, in the case of the website this is information on available subscription plans.

### Plans

Retrieve current plans that are available to subscribe to.

#### Request

```http
GET /website/subscription/plans HTTP/1.1
```

#### Response

The reference field relates to the identifier required by Stripe to setup the subscription.

It is possible to calculate an annual price for a plan for example if you perform `price * interval * frequency` where `frequency` could be *month* or *year* which should be converted to 12 or 1 respectively. As such in the below the annual cost of a subscription would be `125 * 1 * 12 = 1500`.

Note that prices are in lowest denomination, so in the case of GBP this is pence.

```http
HTTP/1.1 202 Accepted

{
  "list": [{
    "_id": "123412341234123412341234",
    "reference": "stripe_reference",
    "name": "Example Plan",
    "currency": "GBP",
    "price": "125",
    "interval": "1"
    "frequency": "month"
  }],
  "total": 4
}
```
