## Website :: Subscription

This section gives access to information about subscriptions, in the case of the website this is information on available subscription plans.

### Plans

Retrieve current plans that are available to subscribe to.

#### Request

```http
GET /website/subscription/plans HTTP/1.1
```

#### Response


| field | description |
| :--- | :--- |
| reference | Relates to the identifier required by Stripe to setup a reoccurring payment |
| name | Display name of the plan |
| currency | The currency of the plan, only plans in GBP are currently supported |
| price | How much in pence (lower currency denomination) will be charged |
| interval | What is the number of times for the frequency to occur before a payment is taken (e.g. interval of `3` and frequency of `month` would mean once every 3 months) |
| frequency | The time period that should pass before a payment is taken value values are `day`, `week`, `month`, `year` |

It is possible to calculate the annual price for a plan for example if you perform `price * frequency / interval` where `frequency` should be converted to 365 (day), 52 (week), 12 (month) or 1 (year). As such in the below the annual cost of a subscription would be `125 * 1 * 12 = 1500 pence`.

> Note: Prices are in lowest denomination, so in the case of GBP this is pence.

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
