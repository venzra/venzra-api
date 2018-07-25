## Store :: Locations

Locations are managed in the admin console, they provide a way to show a customer where they can visit and what the purpose of that location is, e.g. a high street store or an office.

### Retrieve all records

Access a list of all locations that have been created for the store.

#### Request

```http
GET /store/locations HTTP/1.1
```

#### Response

| field | description |
| :--- | :--- |
| displayName | The name given to this location. |
| address | Full address information to enable finding this location. |
| featureImage | A reference to the feature image which should be displayed on the site (see displaying images). |
| usage | Possible statuses are `CREATED`, `AUTHORISED`, `PROCESSING`, `DISPATCHED`, `DELIVERED`, `REFUNDED`. |

Default ordering of results is by `displayName`.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "list": [{
    "_id": "123412341234123412341234",
    "displayName": "Example store location",
    "address": {
      "addressee": "Wade Wilson",
      "street": "Pandora Street",
      "county": "Vancouver",
      "postalCode": "V5K 1V5",
      "country": "CAN"
    },
    "featureImage": "567856785678567856785678",
    "usage": "STORE",
    "created": "2018-01-01T00:00:00.000Z"
  }],
  "total": 2
}
```
