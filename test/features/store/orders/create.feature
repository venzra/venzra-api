@Store @Orders @OrdersCreate
Feature: Place an order using cart information

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName         | gateway                         | transactions                      | status |
      | Orders Create One | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
      | Orders Create Two | { "privateKey": "pk_xxxxxxxx" } | { "rate": "0.021", "base": "10" } | ACTIVE |
    And there are the following "customers" records in the database
      | identity                         | password | addresses                                                                                                          | status | subscription               |
      | orders-create-one@venzra-test.io | PASSWORD | [{ "addressee": "Mr Address", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" }] | ACTIVE | {{ subscriptions[1]._id }} |
    And there are the following "shipping" records in the database
      | subscription               | displayName | cartMinimum | cartMaximum | currentPrice | shipmentTime |
      | {{ subscriptions[1]._id }} | Example A   | 0           | 0           | 200          | 24           |
      | {{ subscriptions[1]._id }} | Example B   | 0           | 0           | 500          | 48           |
      | {{ subscriptions[2]._id }} | Example C   | 0           | 0           | 0            | 72           |
    And there are the following "images" records in the database
      | subscription               | name                 | usage     | size |
      | {{ subscriptions[1]._id }} | OrdersCreate Image A | promotion | 1024 |
      | {{ subscriptions[2]._id }} | OrdersCreate Image B | promotion | 1024 |
    And there are the following "products" records in the database
      | subscription               | code          | slug             | displayName      | description           | promotionalImage    | currentPrice | status   |
      | {{ subscriptions[1]._id }} | CREATE-01-001 | orders-create-a  | Orders Create A  | Automated description | {{ images[1]._id }} | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | CREATE-01-002 | orders-create-aa | Orders Create AA | Automated description | {{ images[1]._id }} | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | CREATE-01-003 | orders-create-b  | Orders Create B  | Automated description | {{ images[1]._id }} | 999          | INACTIVE |
      | {{ subscriptions[2]._id }} | CREATE-02-001 | orders-create-a  | Orders Create A  | Automated description | {{ images[2]._id }} | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | CREATE-02-002 | orders-create-b  | Orders Create B  | Automated description | {{ images[2]._id }} | 999          | INACTIVE |
    And there are the following "carts" records in the database
      | subscription               | ip        | items                                                                                                                                   |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | []                                                                                                                                      |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | [{ "product": "{{ products[1]._id }}", "quantity": 2 }, { "product": "{{ products[2]._id }}" }, { "product": "{{ products[3]._id }}" }] |
      | {{ subscriptions[2]._id }} | 127.0.0.1 | [{ "product": "{{ products[4]._id }}" }, { "product": "{{ products[5]._id }}" }]                                                        |

  Scenario: Missing request body throws required fields error
    Given the request origin headers are set to "orders-create-one.venzra-test.io"
    When I make an empty POST request to the API endpoint "/store/orders" as "order"
    Then the status returned from the "order" request should be a 401 error

  Scenario: Missing request body throws required fields error
    Given the request origin headers are set to "orders-create-one.venzra-test.io"
    And I am logged in with the "orders-create-one@venzra-test.io" account
    When I make an empty POST request to the API endpoint "/store/orders" as "order"
    Then there should be a 400 error from the "order" request that contains:
      | message           | detail                                                                           |
      | Validation failed | ["cart required", "destination required", "shipping required", "token required"] |

  Scenario: Handle a rejection from stripe occurring when attempting to place an order
    Given the request origin headers are set to "orders-create-one.venzra-test.io"
    And I am logged in with the "orders-create-one@venzra-test.io" account
    And there is a POST consumer at "https://api.stripe.com" for "/v1/charges" that will return "stripe/charges/create-invalid.json" with status 400
    When I make a POST request to the API endpoint "/store/orders" as "order" using:
      | cart               | shipping              | token                                    | destination                         |
      | {{ carts[2]._id }} | {{ shipping[2]._id }} | { "id": "tok_xxxxxxxxxxxxxxxxxxxxxxxx" } | {{ customers[1].addresses[1]._id }} |
    Then there should be a 503 error from the "order" request that contains:
      | message           | detail |
      | Third party error | []     |

  Scenario: Cannot use a cart from another subscription to place an order
    Given the request origin headers are set to "orders-create-one.venzra-test.io"
    And I am logged in with the "orders-create-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/orders" as "order" using:
      | cart               | shipping              | token                                    | destination                         |
      | {{ carts[3]._id }} | {{ shipping[3]._id }} | { "id": "tok_xxxxxxxxxxxxxxxxxxxxxxxx" } | {{ customers[1].addresses[1]._id }} |
    Then there should be a 400 error from the "order" request that contains:
      | message           | detail                               |
      | Validation failed | ["cart invalid", "shipping invalid"] |

  Scenario: Placing an order with required fields successfully creates a new record
    Given the request origin headers are set to "orders-create-one.venzra-test.io"
    And I am logged in with the "orders-create-one@venzra-test.io" account
    And there is a POST consumer at "https://api.stripe.com" for "/v1/charges" that will return "stripe/charges/create-success.json" with status 200 when called with:
      | amount | currency | application_fee | source                       | statement_descriptor |
      | 1116   | gbp      | 33              | tok_xxxxxxxxxxxxxxxxxxxxxxxx | Orders Create One    |
    And there is a GET consumer at "https://api.stripe.com" for "/v1/balance/history/txn_xxxxxxxxxxxxxxxxxxxxxxxx" that will return "stripe/balance/retrieve-history.json" with status 200
    And there is a POST consumer at "https://email.eu-west-1.amazonaws.com" that will return status 200
    When I make a POST request to the API endpoint "/store/orders" as "order" using:
      | cart               | shipping              | token                                    | destination                         |
      | {{ carts[2]._id }} | {{ shipping[2]._id }} | { "id": "tok_xxxxxxxxxxxxxxxxxxxxxxxx" } | {{ customers[1].addresses[1]._id }} |
    Then there should be a 200 response from the "order" request that contains:
      | _id       | reference       |
      | OBJECT_ID | REGEX[^\d{10}$] |
    And the database record for "{{ order._id }}" in the "orders" table equals:
      | _id       | subscription | reference | customer  | items    | destination                                            | billing                                                              | payment                                                 | shipping                     | history  | status  | created   | updated   |
      | OBJECT_ID | OBJECT_ID    | STRING    | OBJECT_ID | ARRAY[3] | OBJECT[_id,addressee,street,county,country,postalCode] | OBJECT[_id,addressee,building,street,city,county,country,postalCode] | OBJECT[reference,name,brand,card,fee,transaction,value] | OBJECT[reference,name,price] | ARRAY[0] | CREATED | DATE_TIME | DATE_TIME |
    And the database record for "{{ order._id }}" in the "orders" table has a field called "payment" that equals:
      | reference                   | name           | brand | card   | fee                                                                                                                                                                                                                                                                                                     | transaction                  | value |
      | ch_xxxxxxxxxxxxxxxxxxxxxxxx | Mr Venzra Test | Visa  | "4242" | { "venzra": { "application": "ca_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "amount": 115, "currency": "gbp", "description": "Venzra Fee", "type": "application_fee" }, "gateway": { "application": null, "amount": 165, "currency": "gbp", "description": "Stripe Fee", "type": "stripe_fee" }, "total": 280 } | txn_xxxxxxxxxxxxxxxxxxxxxxxx | 5000  |
