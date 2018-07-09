## Shipping options

The available options for shipping as set by the subscription account.

### List all options

Load all the available options for shipping.

#### Request

There is no pagination available when querying the shipping options, it is expected that the displayed options are managed on the UI.

> WARNING: In the future shipping will be upgraded and look at basket and customer information to provide more tailored shipping options. While we will envisage this to be a simple upgrade path be wary of implementing complex UI rules here.
  
```http
GET /store/shipping HTTP/1.1
```

#### Response

| field | description |
| :--- | :--- |
| displayName | The visual name to show customer who are going to purchase this product |
| currentPrice | Price in pence (lowest denomination) which the product is now available for, and will be paid for by a customer ordering the product |
| cartMinimum | Price in pence (lowest denomination) which the product was previously available for |
| cartMaximum | Price in pence (lowest denomination) which the product was previously available for |

Default ordering of results is by `currentPrice`.

```http
HTTP/1.1 202 Accepted

{
  "list": {
    "_id": "123412341234123412341234",
    "displayName": "Next day delivery",
    "currentPrice": 2499,
    "cartMinimum": 0,
    "cartMaximum": 10000
  },
  "total": 5
}
```
