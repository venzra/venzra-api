@Store @Orders @OrdersSearch
Feature: Creation of a new product entry

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName         | gateway                         | transactions                      | status |
      | Orders Search One | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
      | Orders Search Two | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
    Given there are the following "customers" records in the database
      | identity                           | password | status | subscription               |
      | orders-search-one@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-search-two@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-search-three@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "shipping" records in the database
      | subscription               | displayName | cartMinimum | cartMaximum | currentPrice | shipmentTime |
      | {{ subscriptions[1]._id }} | Example A   | 0           | 0           | 100          | 24           |
      | {{ subscriptions[1]._id }} | Example B   | 0           | 0           | 150          | 48           |
      | {{ subscriptions[2]._id }} | Example C   | 0           | 0           | 100          | 72           |
    And there are the following "images" records in the database
      | subscription               | name                 | usage     | size |
      | {{ subscriptions[1]._id }} | OrdersSearch Image A | promotion | 1024 |
      | {{ subscriptions[2]._id }} | OrdersSearch Image B | promotion | 1024 |
    And there are the following "products" records in the database
      | subscription               | code          | slug             | displayName      | description           | promotionalImage    | currentPrice | status   |
      | {{ subscriptions[1]._id }} | SEARCH-01-001 | orders-search-a  | Orders Search A  | Automated description | {{ images[1]._id }} | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-002 | orders-search-aa | Orders Search AA | Automated description | {{ images[1]._id }} | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-003 | orders-search-b  | Orders Search B  | Automated description | {{ images[1]._id }} | 999          | INACTIVE |
      | {{ subscriptions[2]._id }} | SEARCH-02-001 | orders-search-a  | Orders Search A  | Automated description | {{ images[1]._id }} | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | SEARCH-02-002 | orders-search-b  | Orders Search B  | Automated description | {{ images[1]._id }} | 999          | INACTIVE |
    And there are the following "orders" records in the database in series
      | subscription               | customer               | reference  | shipping                                                                    | destination                                                                                                       | billing                                                                                                              | items                                                                                                                                              | payment                                                                                                                                                                                                                                                                                  |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 1111111111 | { "reference": "{{ shipping[1]._id }}", "name": "Example A", "price": 100 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "5", "price": "15" }]                                                                           | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example One", "card": "2345", "brand": "Visa", "fee": { "venzra": { "amount": 14, "currency": "gbp" }, "gateway": { "amount": 25, "currency": "gbp" }, "total": 39 }, "value": 175 }        |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 2222222222 | { "reference": "{{ shipping[2]._id }}", "name": "Example B", "price": 150 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[2]._id }}", "quantity": "1", "price": "100" }, { "product": "{{ products[3]._id }}", "quantity": "2", "price": "500" }] | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Two", "card": "3456", "brand": "MasterCard", "fee": { "venzra": { "amount": 36, "currency": "gbp" }, "gateway": { "amount": 56, "currency": "gbp" }, "total": 92 }, "value": 1250 } |
      | {{ subscriptions[1]._id }} | {{ customers[2]._id }} | 3333333333 | { "reference": "{{ shipping[3]._id }}", "name": "Example C", "price": 100 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[3]._id }}", "quantity": "2", "price": "500" }]                                                                          | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Three", "card": "4567", "brand": "Visa", "fee": { "venzra": { "amount": 33, "currency": "gbp" }, "gateway": { "amount": 52, "currency": "gbp" }, "total": 85 }, "value": 1100 }     |

  Scenario: Requesting a list of orders should return only records for that account (account one)
    Given the request origin headers are set to "orders-search-one.venzra-test.io"
    And I am logged in with the "orders-search-one@venzra-test.io" account
    When I make a GET request to the API endpoint "/store/orders" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[2] | 2     | 0    | 5     |
    And the "order" request that has a "list" field and row 1 contains:
      | _id       | reference    | items    | shipping                                                                    | destination | payment                                                                         | status  | created   |
      | OBJECT_ID | "2222222222" | ARRAY[2] | { "reference": "{{ shipping[2]._id }}", "name": "Example B", "price": 150 } | OBJECT      | { "name": "Example Two", "card": "3456", "brand": "MasterCard", "value": 1250 } | CREATED | DATE_TIME |

  Scenario: Requesting a list of orders should return only records for that account (account two)
    Given the request origin headers are set to "orders-search-one.venzra-test.io"
    And I am logged in with the "orders-search-two@venzra-test.io" account
    When I make a GET request to the API endpoint "/store/orders" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[1] | 1     | 0    | 5     |
    And the "order" request that has a "list" field and row 1 contains:
      | _id       | reference    | items                                                                                                                                                                          | shipping                                                                    | destination | payment                                                                     | status  | created   |
      | OBJECT_ID | "3333333333" | [{ "price": 500, "product": { "slug": "orders-search-b", "displayName": "Orders Search B", "promotionalImage": "{{ images[1]._id }}", "status": "INACTIVE" }, "quantity": 2 }] | { "reference": "{{ shipping[3]._id }}", "name": "Example C", "price": 100 } | OBJECT      | { "name": "Example Three", "card": "4567", "brand": "Visa", "value": 1100 } | CREATED | DATE_TIME |

  Scenario: Requesting a list of orders adheres to pagination values for skip and limit
    Given the request origin headers are set to "orders-search-one.venzra-test.io"
    And I am logged in with the "orders-search-one@venzra-test.io" account
    When I make a GET request to the API endpoint "/store/orders?skip=1&limit=2" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[1] | 2     | 1    | 2     |
    And the "order" request that has a "list" field and row 1 contains:
      | _id       | reference    | items    | shipping                                                                    | destination | payment                                                                  | status  | created   |
      | OBJECT_ID | "1111111111" | ARRAY[1] | { "reference": "{{ shipping[1]._id }}", "name": "Example A", "price": 100 } | OBJECT      | { "name": "Example One", "card": "2345", "brand": "Visa", "value": 175 } | CREATED | DATE_TIME |

  Scenario: Requesting a list of orders returns an empty array when none have been placed
    Given the request origin headers are set to "orders-search-two.venzra-test.io"
    And I am logged in with the "orders-search-three@venzra-test.io" account
    When I make a GET request to the API endpoint "/store/orders" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[0] | 0     | 0    | 5     |
