@Admin @Shipping @ShippingRemove
Feature: Remove a shipping option from the database

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | status |
      | Admin Shipping Remove One | ACTIVE |
      | Admin Shipping Remove Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | shipping-remove-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | shipping-remove-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "shipping" records in the database
      | displayName | cartMinimum | cartMaximum | currentPrice | shipmentTime | subscription               |
      | Shipping A  | 0           | 0           | 450          | 24           | {{ subscriptions[1]._id }} |
      | Shipping B  | 5           | 100         | 200          | 72           | {{ subscriptions[1]._id }} |
      | Shipping C  | 20          | 500         | 0            | 48           | {{ subscriptions[2]._id }} |

  Scenario: Removal of a shipping option occurs successfully
    Given I am logged in with the "shipping-remove-one@venzra-test.io" admin account
    When I make a DELETE request to the API endpoint "/admin/shipping/{{ shipping[1]._id }}" as "shipment"
    Then the status returned from the "shipment" request should be 202
    When I make a GET request to the API endpoint "/admin/shipping/{{ shipping[1]._id }}" as "check"
    Then the status returned from the "check" request should be a 404 error

  Scenario: It is not possible to remove a record for another subscription
    Given I am logged in with the "shipping-remove-two@venzra-test.io" admin account
    When I make a DELETE request to the API endpoint "/admin/shipping/{{ shipping[2]._id }}" as "shipment"
    Then the status returned from the "shipment" request should be a 404 error
