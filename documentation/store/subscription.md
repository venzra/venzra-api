## Store subscription details

Whenever you show the store these endpoints are at the heart of all capabilities.

### Retrieve record

Retrieve information about the store for the currently active subscription.

#### Request

```http
GET /store/subscription HTTP/1.1
```

#### Response

| field | description |
| :--- | :--- |
| domainName | This is calculated from the store name and must be unique |
| storeName | The name given to identify this store |
| strapline | Free text set on the admin portal to display |
| icon | A reference to the icon which should be displayed on the site (see displaying images) |
| logo | A reference to the logo which should be displayed on the site (see displaying images) |
| features | Which additional features have been enabled |
| contact | Contains two values `recipient` who will receive the emails and `fields` which can be empty for defaults or may contain a collection of fields which should be captured |
| gateway | The currently active API key for generation of card / payment tokens |

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "_id": "123412341234123412341234",
  "domainName": "example-store",
  "storeName": "Example Store",
  "strapline": "A short but powerful message",
  "icon": "432143214321432143214321",
  "logo": "432143214321432143214321",
  "features": ["ABOUT", "CONTACT"],
  "contact": {
    "recipient": "webmaster@venzra.com",
    "fields": ["NAME", "COMPANY", "EMAIL", "SUBJECT", "MESSAGE"]
  },
  "gateway": "pk_live_xxxxxxxxxxxxxxxxxxxxxxxx",
  "created": "2018-01-01T00:00:00.000Z"
}
```
