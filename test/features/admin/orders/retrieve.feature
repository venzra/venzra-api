@Admin @Orders @OrdersRetrieve
Feature: Browsing of orders that have been placed by customers

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | gateway                         | transactions                      | status |
      | Admin Orders Retrieve One | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
      | Admin Orders Retrieve Two | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | orders-retrieve-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-retrieve-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    Given there are the following "customers" records in the database
      | identity                             | status | subscription               |
      | orders-retrieve-one@venzra-test.io   | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-retrieve-two@venzra-test.io   | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-retrieve-three@venzra-test.io | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                   | usage     | size |
      | {{ subscriptions[1]._id }} | OrdersRetrieve Image A | promotion | 1024 |
      | {{ subscriptions[2]._id }} | OrdersRetrieve Image B | promotion | 1024 |
    And there are the following "products" records in the database
      | subscription               | code          | slug               | displayName        | description           | promotionalImage    | currentPrice | status   |
      | {{ subscriptions[1]._id }} | SEARCH-01-001 | orders-retrieve-a  | Orders Retrieve A  | Automated Description | {{ images[1]._id }} | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-002 | orders-retrieve-aa | Orders Retrieve AA | Automated Description | {{ images[1]._id }} | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-003 | orders-retrieve-b  | Orders Retrieve B  | Automated Description | {{ images[1]._id }} | 999          | INACTIVE |
      | {{ subscriptions[2]._id }} | SEARCH-02-001 | orders-retrieve-a  | Orders Retrieve A  | Automated Description | {{ images[1]._id }} | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | SEARCH-02-002 | orders-retrieve-b  | Orders Retrieve B  | Automated Description | {{ images[1]._id }} | 999          | INACTIVE |
    And there are the following "orders" records in the database in series
      | subscription               | customer               | reference  | shipping                              | destination                                                                                                       | billing                                                                                                              | items                                                                                                                                                                                                                      | payment                                                                                                                                                                                                                                                                                    | status     |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 1111111234 | { "name": "Example A", "price": 100 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "5", "price": "15" }]                                                                                                                                                   | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example One", "card": "0123", "brand": "Visa", "fee": { "venzra": { "amount": 14, "currency": "gbp" }, "gateway": { "amount": 25, "currency": "gbp" }, "total": 39 }, "value": 175 }          | AUTHORISED |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 2222222345 | { "name": "Example B", "price": 150 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "4", "price": "15" }, { "product": "{{ products[2]._id }}", "quantity": "1", "price": "100" }]                                                                          | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Two", "card": "1234", "brand": "MasterCard", "fee": { "venzra": { "amount": 17, "currency": "gbp" }, "gateway": { "amount": 29, "currency": "gbp" }, "total": 39 }, "value": 310 }    | PROCESSING |
      | {{ subscriptions[1]._id }} | {{ customers[2]._id }} | 3333333456 | { "name": "Example C", "price": 200 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "3", "price": "99" }, { "product": "{{ products[2]._id }}", "quantity": "2", "price": "100" }, { "product": "{{ products[3]._id }}", "quantity": "1", "price": "500" }] | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Three", "card": "2345", "brand": "MasterCard", "fee": { "venzra": { "amount": 35, "currency": "gbp" }, "gateway": { "amount": 55, "currency": "gbp" }, "total": 39 }, "value": 1197 } | DISPATCHED |
      | {{ subscriptions[2]._id }} | {{ customers[3]._id }} | 4444444567 | { "name": "Example D", "price": 250 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "2", "price": "99" }, { "product": "{{ products[3]._id }}", "quantity": "1", "price": "500" }]                                                                          | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Four", "card": "3456", "brand": "MasterCard", "fee": { "venzra": { "amount": 30, "currency": "gbp" }, "gateway": { "amount": 47, "currency": "gbp" }, "total": 39 }, "value": 948 }   | DELIVERED  |

  Scenario: Retrival of an order contains the correct response data
    Given I am logged in with the "orders-retrieve-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders/{{ orders[1]._id }}" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | _id       | customer                                                                 | reference    | items    | shipping                              | destination | billing | payment | history  | status     | created   | updated   |
      | OBJECT_ID | { "identity": "orders-retrieve-one@venzra-test.io", "status": "ACTIVE" } | "1111111234" | ARRAY[1] | { "name": "Example A", "price": 100 } | OBJECT      | OBJECT  | OBJECT  | ARRAY[0] | AUTHORISED | DATE_TIME | DATE_TIME |
    And the response path "items" from the "order" request contains:
      | price | product                                                                                                                                                                                                                                                                                                                  | quantity |
      | 15    | { "code": "SEARCH-01-001", "slug": "orders-retrieve-a", "displayName": "Orders Retrieve A", "promotionalImage": { "_id": "{{ images[1]._id }}", "name": "OrdersRetrieve Image A", "usage": "promotion", "path": "{{ subscriptions[1]._id }}/promotion/{{ images[1]._id }}.jpg" },"currentPrice": 9, "status": "ACTIVE" } | 5        |
    And the response path "payment" from the "order" request contains:
      | reference          | transaction                  | name        | card | brand | fee                                                                                                            | value |
      | ch_xxxxxxxxxxxxxxx | txn_xxxxxxxxxxxxxxxxxxxxxxxx | Example One | 0123 | Visa  | { "venzra": { "amount": 14, "currency": "gbp" }, "gateway": { "amount": 25, "currency": "gbp" }, "total": 39 } | 175   |

  Scenario: Another subscription user cannot retrieve a record that does not belong to them
    Given I am logged in with the "orders-retrieve-two@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders/{{ orders[1]._id }}" as "order"
    Then the status returned from the "order" request should be a 404 error
