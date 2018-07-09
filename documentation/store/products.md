## Product information

These endpoints allow for searching and displaying of products to be used on the store. Only products that are in an ACTIVE state can be returned when using these endpoints on the store.

### Retrieve record

Details about an individual product to be sold.

#### Request

**URL Parameters**

- **productId**  
  This is the reference identifier for the product which is unique in the database.
  
```http
GET /store/products/:productId HTTP/1.1
```

#### Response

| field | description |
| :--- | :--- |
| code | The unique product code used to identify this, typically part of your product SKU code |
| slug | A short human readable value used to create a unique URI for the product, this is created from the product display name automatically |
| displayName | The visual name to show customer who are going to purchase this product |
| description | Some descriptive text which supports markdown formatting tags. |
| featureImage | A reference to the feature image which should be displayed on the site (see displaying images) |
| promotionalImage | A reference to a promotional image which should be displayed on the site (see displaying images) |
| previousPrice | Price in pence (lowest denomination) which the product was previously available for |
| currentPrice | Price in pence (lowest denomination) which the product is now available for, and will be paid for by a customer ordering the product |

```http
HTTP/1.1 202 Accepted

{
  "_id": "123412341234123412341234",
  "code": "EXAMPLE-001",
  "slug": "example-product",
  "displayName": "Example Product",
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque fermentum at magna eu mattis.",
  "featureImage": "432143214321432143214321",
  "promotionalImage": "432143214321432143214321",
  "previousPrice": 3000,
  "currentPrice": 2499
}
```

### List all products

Retrieve a list of all the products available on the store, this list is paginated and can be filtered based on navigational options that might be present.

#### Request

**Query parameters**

- **category**  
  A reference ID for a category to show results for, if the category has "child" categories products in all child categories will be returned too
- **search**  
  Find products with a `code`, `displayName` or `description` value that contains the search parameter value, results will be returned based on the relative a weighting of how often this search value occurs.
- **skip**  
  For pagination of results, how many records to "skip"
- **limit**  
  For pagination of results, how many records to "display" (a maximum of 100 can be requested)
  
```http
GET /store/products HTTP/1.1
```

#### Response

| field | description |
| :--- | :--- |
| code | The unique product code used to identify this, typically part of your product SKU code |
| slug | A short human readable value used to create a unique URI for the product, this is created from the product display name automatically |
| displayName | The visual name to show customer who are going to purchase this product |
| promotionalImage | A reference to a promotional image which should be displayed on the site (see displaying images) |
| previousPrice | Price in pence (lowest denomination) which the product was previously available for |
| currentPrice | Price in pence (lowest denomination) which the product is now available for, and will be paid for by a customer ordering the product |

Default ordering of results is by `displayName`.

```http
HTTP/1.1 202 Accepted

{
  "list": {
    "_id": "123412341234123412341234",
    "code": "EXAMPLE-001",
    "slug": "example-product",
    "displayName": "Example Product",
    "promotionalImage": "432143214321432143214321",
    "previousPrice": 3000,
    "currentPrice": 2499
  },
  "total": 5,
  "skip": 2,
  "limit": 1
}
```
