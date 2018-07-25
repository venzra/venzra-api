## Orders information

Create and retrieve orders that a customer has placed.

### Create new record

Generate a new order to be created for a customer. Requires a logged in customer matching the origin domain.

#### Request

**URL Parameters**
  
```http
POST /store/orders HTTP/1.1
Content-Type: application/json

{
  "cart": "example@venzra.com",
  "token": true,
  "destination": {
      "addressee": "Wade Wilson",
      "street": "Pandora Street",
      "county": "Vancouver",
      "postalCode": "V5K 1V5",
      "country": "CAN"
  }
}
```

#### Response

| field | description |
| :--- | :--- |
| reference | A friendly reference (10 digit) number that the customer can use to refer to this order. |

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "_id": "123412341234123412341234",
  "reference": 1111111111
}
```

### List all orders

Retrieve a summary of all orders that have been placed for the currently logged in customer, this can be paginated. Requires a logged in customer matching the origin domain.

#### Request

**Query parameters**

- **skip**  
  For pagination of results, how many records to "skip"
- **limit**  
  For pagination of results, how many records to "display" (a maximum of 100 can be requested)

```http
GET /store/orders HTTP/1.1
```

#### Response

| field | description |
| :--- | :--- |
| destination | Address information that relates to the requested shipping destination for this order. |
| items | A list of items which have been paid for as part of this order. |
| payment | Details of the payment card, note that only limited card information is available for security and data protection purposes. |
| reference | A friendly reference (10 digit) number that the customer can use to refer to this order. |
| shipping | The requested shipping options for this order |
| status | Possible statuses are `CREATED`, `AUTHORISED`, `PROCESSING`, `DISPATCHED`, `DELIVERED`, `REFUNDED` an order can only progress forward on this list of states. |

Default ordering of results is by `created` in reverse chronological order.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "list": {
    "_id": "123412341234123412341234",
    "destination": {
      "addressee": "Wade Wilson",
      "street": "Pandora Street",
      "county": "Vancouver",
      "postalCode": "V5K 1V5",
      "country": "CAN"
    },
    "items": [{
      "product": {
        "slug": "example-product",
        "displayName": "Example product",
        "promotionalImage": "567856785678567856785678",
        "status": "ACTIVE"
      },
      "price": 499,
      "quantity": 2
    }],
    "payment": {
      "name": "Mr Wilson",
      "card": "4242",
      "brand": "Visa",
      "value": 1099
    },
    "reference": "1111111111",
    "shipping": {
      "reference": "123412341234123412341234",
      "name": "Next Day",
      "price": 100
    },
    "status": "AUTHORISED",
    "created": "2018-01-01T00:00:00.000Z"
  },
  "total": 5,
  "skip": 2,
  "limit": 1
}
```
