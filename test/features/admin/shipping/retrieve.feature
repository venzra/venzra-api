@Admin @Shipping @ShippingRetrieve
Feature: Retrieve information for a shipping option

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                   | status |
      | Admin Shipping Retrieve One | ACTIVE |
      | Admin Shipping Retrieve Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                             | password | status | subscription               |
      | shipping-retrieve-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | shipping-retrieve-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "shipping" records in the database
      | displayName | cartMinimum | cartMaximum | currentPrice | shipmentTime | subscription               |
      | Shipping A  | 0           | 0           | 450          | 24           | {{ subscriptions[1]._id }} |
      | Shipping B  | 5           | 100         | 200          | 72           | {{ subscriptions[1]._id }} |
      | Shipping C  | 20          | 500         | 0            | 48           | {{ subscriptions[2]._id }} |

  Scenario: Retrieval of a shipping option contains correct data
    Given I am logged in with the "shipping-retrieve-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/shipping/{{ shipping[1]._id }}" as "shipment"
    Then there should be a 200 response from the "shipment" request that contains:
      | _id       | displayName | cartMinimum | cartMaximum | currentPrice | shipmentTime | created   | updated   |
      | OBJECT_ID | Shipping A  | 0           | 0           | 450          | 24           | DATE_TIME | DATE_TIME |

  Scenario: Another subscription user cannot retrieve a record that does not belong to them
    Given I am logged in with the "shipping-retrieve-two@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/shipping/{{ shipping[1]._id }}" as "shipment"
    Then the status returned from the "shipment" request should be a 404 error
