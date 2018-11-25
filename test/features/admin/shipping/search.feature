@Admin @Shipping @ShippingSearch
Feature: Searching of available shipping options

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | status |
      | Admin Shipping Search One | ACTIVE |
      | Admin Shipping Search Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | shipping-search-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | shipping-search-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
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

  Scenario: Requesting a list of shipping options should return only records for that subscription
    Given I am logged in with the "shipping-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/shipping" as "shipment"
    Then there should be a 200 response from the "shipment" request that contains:
      | list     | total | skip | limit |
      | ARRAY[6] | 6     | 0    | 20    |
    And the response from the "shipment" request has a "list" that contains rows:
      | _id                   | displayName | currentPrice | shipmentTime |
      | {{ shipping[3]._id }} | Shipping C  | 200          | 48           |
      | {{ shipping[6]._id }} | Shipping F  | 200          | 168          |
      | {{ shipping[2]._id }} | Shipping B  | 450          | 72           |
      | {{ shipping[5]._id }} | Shipping E  | 500          | 36           |
      | {{ shipping[1]._id }} | Shipping A  | 900          | 24           |
      | {{ shipping[4]._id }} | Shipping D  | 2000         | 12           |

  Scenario: Requesting a list of shipping options adheres to pagination values for skip and limit
    Given I am logged in with the "shipping-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/shipping?skip=2&limit=3" as "shipment"
    Then there should be a 200 response from the "shipment" request that contains:
      | list     | total | skip | limit |
      | ARRAY[3] | 6     | 2    | 3     |
    And the response from the "shipment" request has a "list" that contains rows:
      | _id                   | displayName | currentPrice | shipmentTime |
      | {{ shipping[2]._id }} | Shipping B  | 450          | 72           |
      | {{ shipping[5]._id }} | Shipping E  | 500          | 36           |
      | {{ shipping[1]._id }} | Shipping A  | 900          | 24           |

  Scenario: Sorting shipping options results by another column than the default
    Given I am logged in with the "shipping-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/shipping?sort=currentPrice&direction=desc" as "shipment"
    Then there should be a 200 response from the "shipment" request that contains:
      | list     | total | skip | limit |
      | ARRAY[6] | 6     | 0    | 20    |
    And the response from the "shipment" request has a "list" that contains rows:
      | _id                   | displayName | currentPrice | shipmentTime |
      | {{ shipping[4]._id }} | Shipping D  | 2000         | 12           |
      | {{ shipping[1]._id }} | Shipping A  | 900          | 24           |
      | {{ shipping[5]._id }} | Shipping E  | 500          | 36           |
      | {{ shipping[2]._id }} | Shipping B  | 450          | 72           |
      | {{ shipping[3]._id }} | Shipping C  | 200          | 48           |
      | {{ shipping[6]._id }} | Shipping F  | 200          | 168          |
