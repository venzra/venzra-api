@Admin @Orders @OrdersUpdate
Feature: Browsing of orders that have been placed by customers

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName               | gateway                         | transactions                      | status |
      | Admin Orders Update One | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
      | Admin Orders Update Two | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                         | password | status | subscription               |
      | orders-update-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-update-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    Given there are the following "customers" records in the database
      | identity                           | status | subscription               |
      | orders-update-one@venzra-test.io   | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-update-two@venzra-test.io   | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-update-three@venzra-test.io | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                 | usage     | size |
      | {{ subscriptions[1]._id }} | OrdersUpdate Image A | promotion | 1024 |
      | {{ subscriptions[2]._id }} | OrdersUpdate Image B | promotion | 1024 |
    And there are the following "products" records in the database
      | subscription               | code          | slug             | displayName      | description           | promotionalImage    | currentPrice | status   |
      | {{ subscriptions[1]._id }} | SEARCH-01-001 | orders-update-a  | Orders Update A  | Automated Description | {{ images[1]._id }} | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-002 | orders-update-aa | Orders Update AA | Automated Description | {{ images[1]._id }} | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-003 | orders-update-b  | Orders Update B  | Automated Description | {{ images[1]._id }} | 999          | INACTIVE |
      | {{ subscriptions[2]._id }} | SEARCH-02-001 | orders-update-a  | Orders Update A  | Automated Description | {{ images[1]._id }} | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | SEARCH-02-002 | orders-update-b  | Orders Update B  | Automated Description | {{ images[1]._id }} | 999          | INACTIVE |
    And there are the following "orders" records in the database in series
      | subscription               | customer               | reference  | shipping                              | destination                                                                                                       | billing                                                                                                              | items                                                                                                                                                                                                                      | payment                                                                                                                                                                                                                                                                                                                              | status     |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 1111111234 | { "name": "Example A", "price": 100 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "5", "price": "15" }]                                                                                                                                                   | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example One", "card": "0123", "brand": "Visa", "fee": { "venzra": { "amount": 14, "currency": "gbp" }, "gateway": { "amount": 25, "currency": "gbp" }, "total": 39 }, "value": 175 }                                                    | AUTHORISED |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 2222222345 | { "name": "Example B", "price": 150 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "4", "price": "15" }, { "product": "{{ products[2]._id }}", "quantity": "1", "price": "100" }]                                                                          | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Two", "card": "1234", "brand": "MasterCard", "fee": { "venzra": { "amount": 17, "currency": "gbp" }, "gateway": { "amount": 29, "currency": "gbp" }, "total": 39 }, "value": 310 }                                              | PROCESSING |
      | {{ subscriptions[1]._id }} | {{ customers[2]._id }} | 3333333456 | { "name": "Example C", "price": 200 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "3", "price": "99" }, { "product": "{{ products[2]._id }}", "quantity": "2", "price": "100" }, { "product": "{{ products[3]._id }}", "quantity": "1", "price": "500" }] | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Three", "card": "2345", "brand": "MasterCard", "fee": { "venzra": { "amount": 35, "currency": "gbp" }, "gateway": { "amount": 55, "currency": "gbp" }, "total": 39 }, "value": 1197 }                                           | DISPATCHED |
      | {{ subscriptions[1]._id }} | {{ customers[2]._id }} | 4444444567 | { "name": "Example D", "price": 200 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "3", "price": "99" }, { "product": "{{ products[2]._id }}", "quantity": "2", "price": "100" }, { "product": "{{ products[3]._id }}", "quantity": "1", "price": "500" }] | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Four", "card": "3456", "brand": "MasterCard", "fee": { "venzra": { "amount": 35, "currency": "gbp", "refund": 35 }, "gateway": { "amount": 55, "currency": "gbp", "refund": 55 }, "total": 0 }, "value": 1197, "refund": 1197 } | REFUNDED   |
      | {{ subscriptions[2]._id }} | {{ customers[3]._id }} | 5555555678 | { "name": "Example E", "price": 250 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "2", "price": "99" }, { "product": "{{ products[3]._id }}", "quantity": "1", "price": "500" }]                                                                          | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Five", "card": "4567", "brand": "MasterCard", "fee": { "venzra": { "amount": 30, "currency": "gbp" }, "gateway": { "amount": 47, "currency": "gbp" }, "total": 39 }, "value": 948 }                                             | DELIVERED  |


  Scenario: If no update information is provided then the request is ignored
    Given I am logged in with the "orders-update-one@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/orders/{{ orders[1]._id }}" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | _id       | customer                                                               | reference    | items    | shipping                              | destination | billing | payment | history  | status     | created   | updated   |
      | OBJECT_ID | { "identity": "orders-update-one@venzra-test.io", "status": "ACTIVE" } | "1111111234" | ARRAY[1] | { "name": "Example A", "price": 100 } | OBJECT      | OBJECT  | OBJECT  | ARRAY[0] | AUTHORISED | DATE_TIME | DATE_TIME |
    And the response path "items" from the "order" request contains:
      | price | product                                                                                                                                                                                                                                                                                                            | quantity |
      | 15    | { "code": "SEARCH-01-001", "slug": "orders-update-a", "displayName": "Orders Update A", "promotionalImage": { "_id": "{{ images[1]._id }}", "name": "OrdersUpdate Image A", "usage": "promotion", "path": "{{ subscriptions[1]._id }}/promotion/{{ images[1]._id }}.jpg" },"currentPrice": 9, "status": "ACTIVE" } | 5        |
    And the response path "payment" from the "order" request contains:
      | reference          | transaction                  | name        | card | brand | fee                                                                                                            | value |
      | ch_xxxxxxxxxxxxxxx | txn_xxxxxxxxxxxxxxxxxxxxxxxx | Example One | 0123 | Visa  | { "venzra": { "amount": 14, "currency": "gbp" }, "gateway": { "amount": 25, "currency": "gbp" }, "total": 39 } | 175   |

  Scenario: Attempting to update an order that does not belong to the account subscription is rejected
    Given I am logged in with the "orders-update-two@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/orders/{{ orders[1]._id }}" as "order" using:
      | op      | path   | value  |
      | replace | status | ACTIVE |
    Then the status returned from the "order" request should be a 404 error

  Scenario: Update order information with values provided which can be altered
    Given I am logged in with the "orders-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/orders/{{ orders[1]._id }}" as "order" using:
      | op      | path     | value      |
      | replace | courier  | City Link  |
      | replace | tracking | VZ0000001  |
      | replace | status   | PROCESSING |
    Then there should be a 200 response from the "order" request that contains:
      | _id       | customer | reference    | items    | shipping                                                                               | destination | billing | payment | history  | status     | created   | updated   |
      | OBJECT_ID | OBJECT   | "1111111234" | ARRAY[1] | { "name": "Example A", "courier": "City Link", "tracking": "VZ0000001", "price": 100 } | OBJECT      | OBJECT  | OBJECT  | ARRAY[1] | PROCESSING | DATE_TIME | DATE_TIME |
    And the "order" request that has a "history" field and row 1 contains:
      | account | field  | previous   | next       | created   |
      | OBJECT  | status | AUTHORISED | PROCESSING | DATE_TIME |

  Scenario: Should not update an order status once it has been refunded
    Given I am logged in with the "orders-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/orders/{{ orders[4]._id }}" as "order" using:
      | op      | path   | value     |
      | replace | status | DELIVERED |
    Then there should be a 200 response from the "order" request that contains:
      | _id       | customer | reference    | items    | shipping                              | destination | billing | payment | history  | status   | created   | updated   |
      | OBJECT_ID | OBJECT   | "4444444567" | ARRAY[3] | { "name": "Example D", "price": 200 } | OBJECT      | OBJECT  | OBJECT  | ARRAY[0] | REFUNDED | DATE_TIME | DATE_TIME |
