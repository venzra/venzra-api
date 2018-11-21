@Admin @Orders @OrdersSearch
Feature: Browsing of orders that have been placed by customers

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | gateway                         | transactions                      | status |
      | Admin Orders Search One   | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
      | Admin Orders Search Two   | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
      | Admin Orders Search Three | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | orders-search-one@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-search-two@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
      | orders-search-three@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[3]._id }} |
    Given there are the following "customers" records in the database
      | identity                           | status | subscription               |
      | orders-search-one@venzra-test.io   | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-search-two@venzra-test.io   | ACTIVE | {{ subscriptions[1]._id }} |
      | orders-search-three@venzra-test.io | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                 | usage     | size |
      | {{ subscriptions[1]._id }} | OrdersSearch Image A | promotion | 1024 |
      | {{ subscriptions[2]._id }} | OrdersSearch Image B | promotion | 1024 |
    And there are the following "products" records in the database
      | subscription               | code          | slug             | displayName      | description           | promotionalImage    | currentPrice | status   |
      | {{ subscriptions[1]._id }} | SEARCH-01-001 | orders-search-a  | Orders Search A  | Automated Description | {{ images[1]._id }} | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-002 | orders-search-aa | Orders Search AA | Automated Description | {{ images[1]._id }} | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-003 | orders-search-b  | Orders Search B  | Automated Description | {{ images[1]._id }} | 999          | INACTIVE |
      | {{ subscriptions[2]._id }} | SEARCH-02-001 | orders-search-a  | Orders Search A  | Automated Description | {{ images[1]._id }} | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | SEARCH-02-002 | orders-search-b  | Orders Search B  | Automated Description | {{ images[1]._id }} | 999          | INACTIVE |
    And there are the following "orders" records in the database in series
      | subscription               | customer               | reference  | shipping                              | destination                                                                                                       | billing                                                                                                              | items                                                                                                                                                                                                                      | payment                                                                                                                                                                                                                                                                                                                      | status     |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 1111111234 | { "name": "Example A", "price": 100 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "5", "price": "15" }]                                                                                                                                                   | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example One", "card": "0123", "brand": "Visa", "fee": { "venzra": { "amount": 14, "currency": "gbp" }, "gateway": { "amount": 25, "currency": "gbp" }, "total": 39 }, "value": 175 }                                            | CREATED    |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 2222222345 | { "name": "Example B", "price": 150 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "4", "price": "15" }, { "product": "{{ products[2]._id }}", "quantity": "1", "price": "100" }]                                                                          | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Two", "card": "1234", "brand": "MasterCard", "fee": { "venzra": { "amount": 17, "currency": "gbp" }, "gateway": { "amount": 29, "currency": "gbp" }, "total": 39 }, "value": 310 }                                      | AUTHORISED |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 3333333456 | { "name": "Example C", "price": 200 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "3", "price": "99" }, { "product": "{{ products[2]._id }}", "quantity": "2", "price": "100" }, { "product": "{{ products[3]._id }}", "quantity": "1", "price": "500" }] | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Three", "card": "2345", "brand": "MasterCard", "fee": { "venzra": { "amount": 35, "currency": "gbp" }, "gateway": { "amount": 55, "currency": "gbp" }, "total": 39 }, "value": 1197 }                                   | AUTHORISED |
      | {{ subscriptions[1]._id }} | {{ customers[2]._id }} | 4444444567 | { "name": "Example D", "price": 250 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[1]._id }}", "quantity": "2", "price": "99" }, { "product": "{{ products[3]._id }}", "quantity": "1", "price": "500" }]                                                                          | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Four", "card": "3456", "brand": "MasterCard", "fee": { "venzra": { "amount": 30, "currency": "gbp" }, "gateway": { "amount": 47, "currency": "gbp" }, "total": 39 }, "value": 948 }                                     | PROCESSING |
      | {{ subscriptions[1]._id }} | {{ customers[1]._id }} | 5555555678 | { "name": "Example E", "price": 300 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[2]._id }}", "quantity": "1", "price": "500" }]                                                                                                                                                  | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Five", "card": "4567", "brand": "Visa", "fee": { "venzra": { "amount": 27, "currency": "gbp", "refund": 27 }, "gateway": { "amount": 43, "currency": "gbp", "refund": 43 }, "total": 0 }, "value": 800, "refund": 800 } | REFUNDED   |
      | {{ subscriptions[1]._id }} | {{ customers[2]._id }} | 6666666789 | { "name": "Example F", "price": 350 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[3]._id }}", "quantity": "10", "price": "99" }]                                                                                                                                                  | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Six", "card": "5678", "brand": "Visa", "fee": { "venzra": { "amount": 38, "currency": "gbp" }, "gateway": { "amount": 59, "currency": "gbp" }, "total": 39 }, "value": 1340 }                                           | DELIVERED  |
      | {{ subscriptions[2]._id }} | {{ customers[3]._id }} | 7777777890 | { "name": "Example G", "price": 400 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[4]._id }}", "quantity": "2", "price": "350" }]                                                                                                                                                  | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Seven", "card": "6789", "brand": "MasterCard", "fee": { "venzra": { "amount": 33, "currency": "gbp" }, "gateway": { "amount": 52, "currency": "gbp" }, "total": 85 }, "value": 1100 }                                   | PROCESSING |
      | {{ subscriptions[2]._id }} | {{ customers[3]._id }} | 8888888901 | { "name": "Example H", "price": 500 } | { "addressee": "Mr Shipping", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | { "addressee": "Mr Billing", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } | [{ "product": "{{ products[4]._id }}", "quantity": "1", "price": "300" }, { "product": "{{ products[5]._id }}", "quantity": "2", "price": "200" }]                                                                         | { "reference": "ch_xxxxxxxxxxxxxxx", "transaction": "txn_xxxxxxxxxxxxxxxxxxxxxxxx", "name": "Example Eight", "card": "7890", "brand": "Visa", "fee": { "venzra": { "amount": 35, "currency": "gbp" }, "gateway": { "amount": 55, "currency": "gbp" }, "total": 39 }, "value": 1200 }                                         | DELIVERED  |

  Scenario: Requesting a list of orders should return only records for that account (account one)
    Given I am logged in with the "orders-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[6] | 6     | 0    | 20    |
    And the "order" request that has a "list" field and row 1 contains:
      | _id       | customer                                                               | reference    | items    | shipping                              | destination | payment                                                                                                                                                                                          | status    | created   |
      | OBJECT_ID | { "identity": "orders-search-two@venzra-test.io", "status": "ACTIVE" } | "6666666789" | ARRAY[1] | { "name": "Example F", "price": 350 } | OBJECT      | { "name": "Example Six", "card": "5678", "brand": "Visa", "fee": { "venzra": { "amount": 38, "currency": "gbp" }, "gateway": { "amount": 59, "currency": "gbp" }, "total": 39 }, "value": 1340 } | DELIVERED | DATE_TIME |

  Scenario: Requesting a list of orders should return only records for that account (account two)
    Given I am logged in with the "orders-search-two@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[2] | 2     | 0    | 20    |
    And the "order" request that has a "list" field and row 2 contains:
      | _id       | customer                                                                 | reference    | items                                                                                                                                                                                                                                                                                                                                                               | shipping                              | destination | payment                                                                                                                                                                                                  | status     | created   |
      | OBJECT_ID | { "identity": "orders-search-three@venzra-test.io", "status": "ACTIVE" } | "7777777890" | [{ "price": 350, "product": { "code": "SEARCH-02-001", "slug": "orders-search-a", "displayName": "Orders Search A", "promotionalImage": { "_id": "{{ images[1]._id }}", "name": "OrdersSearch Image A", "usage": "promotion", "path": "{{ subscriptions[1]._id }}/promotion/{{ images[1]._id }}.jpg" }, "currentPrice": 999, "status": "ACTIVE" }, "quantity": 2 }] | { "name": "Example G", "price": 400 } | OBJECT      | { "name": "Example Seven", "card": "6789", "brand": "MasterCard", "fee": { "venzra": { "amount": 33, "currency": "gbp" }, "gateway": { "amount": 52, "currency": "gbp" }, "total": 85 }, "value": 1100 } | PROCESSING | DATE_TIME |

  Scenario: Requesting a list of orders adheres to pagination values for skip and limit
    Given I am logged in with the "orders-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders?skip=3&limit=2" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[2] | 6     | 3    | 2     |
    And the "order" request that has a "list" field and row 1 contains:
      | _id       | customer                                                               | reference    | items    | shipping                              | destination | payment                                                                                                                                                                                                  | status     | created   |
      | OBJECT_ID | { "identity": "orders-search-one@venzra-test.io", "status": "ACTIVE" } | "3333333456" | ARRAY[3] | { "name": "Example C", "price": 200 } | OBJECT      | { "name": "Example Three", "card": "2345", "brand": "MasterCard", "fee": { "venzra": { "amount": 35, "currency": "gbp" }, "gateway": { "amount": 55, "currency": "gbp" }, "total": 39 }, "value": 1197 } | AUTHORISED | DATE_TIME |

  Scenario: Filtering order results by reference returns based on partial matching
    Given I am logged in with the "orders-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders?search=45" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[3] | 3     | 0    | 20    |
    And the response path "list" from the "order" request partially contains:
      | _id                 | reference    |
      | {{ orders[4]._id }} | "4444444567" |
      | {{ orders[3]._id }} | "3333333456" |
      | {{ orders[2]._id }} | "2222222345" |

  Scenario: Filtering order results by status returns based on partial matching
    Given I am logged in with the "orders-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders?status=PROCESSING" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[1] | 1     | 0    | 20    |
    And the response path "list" from the "order" request partially contains:
      | _id                 | status     |
      | {{ orders[4]._id }} | PROCESSING |

  Scenario: Sorting order results in reverse
    Given I am logged in with the "orders-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders?direction=asc" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[6] | 6     | 0    | 20    |
    And the response path "list" from the "order" request partially contains:
      | _id                 | reference    |
      | {{ orders[1]._id }} | "1111111234" |
      | {{ orders[2]._id }} | "2222222345" |
      | {{ orders[3]._id }} | "3333333456" |

  Scenario: Sorting order results by another column than the default
    Given I am logged in with the "orders-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders?sort=status" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[6] | 6     | 0    | 20    |
    And the response path "list" from the "order" request partially contains:
      | _id                 | reference    |
      | {{ orders[2]._id }} | "2222222345" |
      | {{ orders[3]._id }} | "3333333456" |
      | {{ orders[1]._id }} | "1111111234" |
      | {{ orders[6]._id }} | "6666666789" |
      | {{ orders[4]._id }} | "4444444567" |
      | {{ orders[5]._id }} | "5555555678" |

  Scenario: Requesting a list of orders returns an empty array when none have been placed
    Given I am logged in with the "orders-search-three@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/orders" as "order"
    Then there should be a 200 response from the "order" request that contains:
      | list     | total | skip | limit |
      | ARRAY[0] | 0     | 0    | 20    |
