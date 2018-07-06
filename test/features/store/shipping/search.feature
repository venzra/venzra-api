@Store @Shipping @ShippingSearch
Feature: Searching of available shipping options

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName           | status |
      | Shipping Search One | ACTIVE |
      | Shipping Search Two | ACTIVE |
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
    Given the request origin headers are set to "shipping-search-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/shipping" as "shipment"
    Then there should be a 200 response from the "shipment" request that contains:
      | list     | total |
      | ARRAY[6] | 6     |
    And the response from the "shipment" request has a "list" that contains rows:
      | _id                   | displayName | currentPrice | cartMinimum | cartMaximum |
      | {{ shipping[3]._id }} | Shipping C  | 200          | 10          | 200         |
      | {{ shipping[6]._id }} | Shipping F  | 200          | 100         | 200         |
      | {{ shipping[2]._id }} | Shipping B  | 450          | 5           | 100         |
      | {{ shipping[5]._id }} | Shipping E  | 500          | 50          | 500         |
      | {{ shipping[1]._id }} | Shipping A  | 900          | 0           | 0           |
      | {{ shipping[4]._id }} | Shipping D  | 2000         | 20          | 1000        |
