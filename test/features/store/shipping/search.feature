@Store @Shipping @ShippingSearch
Feature: Searching of available shipping options

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | status |
      | Store Shipping Search One | ACTIVE |
      | Store Shipping Search Two | ACTIVE |
    And there are the following "shipping" records in the database
      | displayName | cartMinimum | cartMaximum | currentPrice | shipmentTime | subscription               |
      | Shipping A  | 0           | 0           | 900          | 24           | {{ subscriptions[1]._id }} |
      | Shipping B  | 5           | 100         | 450          | 72           | {{ subscriptions[1]._id }} |
      | Shipping C  | 10          | 200         | 200          | 48           | {{ subscriptions[1]._id }} |
      | Shipping D  | 20          | 1000        | 2000         | 12           | {{ subscriptions[1]._id }} |
      | Shipping E  | 50          | 500         | 500          | 36           | {{ subscriptions[1]._id }} |
      | Shipping F  | 100         | 200         | 200          | 168          | {{ subscriptions[1]._id }} |
      | Shipping G  | 50          | 50          | 100          | 24           | {{ subscriptions[2]._id }} |
      | Shipping H  | 0           | 50          | 0            | 24           | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                 | usage     | size |
      | {{ subscriptions[1]._id }} | CartRetrieve Image A | promotion | 1024 |
    And there are the following "products" records in the database
      | subscription               | code            | slug             | displayName      | description           | promotionalImage    | currentPrice | status |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-001 | cart-retrieve-a  | Cart Retrieve A  | Automated description | {{ images[1]._id }} | 9            | ACTIVE |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-002 | cart-retrieve-aa | Cart Retrieve AA | Automated description | {{ images[1]._id }} | 99           | ACTIVE |
    And there are the following "carts" records in the database
      | subscription               | ip        | items                                                                                                          |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | []                                                                                                             |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | [{ "product": "{{ products[1]._id }}" }]                                                                       |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | [{ "product": "{{ products[1]._id }}", "quantity": 2 }, { "product": "{{ products[2]._id }}", "quantity": 3 }] |

  Scenario: Requesting a list of shipping options should return only records valid for the current cart (empty cart)
    Given the request origin headers are set to "store-shipping-search-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[1]._id }}"
    When I make a GET request to the API endpoint "/store/shipping" as "shipment"
    Then there should be a 200 response from the "shipment" request that contains:
      | list     | total |
      | ARRAY[1] | 1     |
    And the response from the "shipment" request has a "list" that contains rows:
      | _id                   | displayName | currentPrice | cartMinimum | cartMaximum |
      | {{ shipping[1]._id }} | Shipping A  | 900          | 0           | 0           |

  Scenario: Requesting a list of shipping options should return only records valid for the current cart (basic cart)
    Given the request origin headers are set to "store-shipping-search-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[2]._id }}"
    When I make a GET request to the API endpoint "/store/shipping" as "shipment"
    Then there should be a 200 response from the "shipment" request that contains:
      | list     | total |
      | ARRAY[2] | 2     |
    And the response from the "shipment" request has a "list" that contains rows:
      | _id                   | displayName | currentPrice | cartMinimum | cartMaximum |
      | {{ shipping[2]._id }} | Shipping B  | 450          | 5           | 100         |
      | {{ shipping[1]._id }} | Shipping A  | 900          | 0           | 0           |

  Scenario: Requesting a list of shipping options should return only records valid for the current cart (complex cart)
    Given the request origin headers are set to "store-shipping-search-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[3]._id }}"
    When I make a GET request to the API endpoint "/store/shipping" as "shipment"
    Then there should be a 200 response from the "shipment" request that contains:
      | list     | total |
      | ARRAY[3] | 3     |
    And the response from the "shipment" request has a "list" that contains rows:
      | _id                   | displayName | currentPrice | cartMinimum | cartMaximum |
      | {{ shipping[5]._id }} | Shipping E  | 500          | 50          | 500         |
      | {{ shipping[1]._id }} | Shipping A  | 900          | 0           | 0           |
      | {{ shipping[4]._id }} | Shipping D  | 2000         | 20          | 1000        |
