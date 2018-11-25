@Admin @Shipping @ShippingCreate
Feature: Creation of a new shipping entry

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | status |
      | Admin Shipping Create One | ACTIVE |
      | Admin Shipping Create Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | shipping-create-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | shipping-create-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |

  Scenario: An empty request to create a shipping record fails validation
    Given I am logged in with the "shipping-create-one@venzra-test.io" admin account
    When I make an empty POST request to the API endpoint "/admin/shipping" as "shipment"
    Then there should be a 400 error from the "shipment" request that contains:
      | message           | detail                                            |
      | Validation failed | ["displayName required", "currentPrice required"] |

  Scenario: A valid request to create a new shipping record is successful with defaults entered when not set
    Given I am logged in with the "shipping-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/shipping" as "shipment" using:
      | displayName          | currentPrice |
      | Automated Shipping A | 999          |
    Then there should be a 200 response from the "shipment" request that contains:
      | _id       | displayName          | cartMinimum | cartMaximum | currentPrice | shipmentTime | created   | updated   |
      | OBJECT_ID | Automated Shipping A | 0           | 0           | 999          | 48           | DATE_TIME | DATE_TIME |

  Scenario: A valid request to create a new shipping record is successful with all defaults overridden correctly
    Given I am logged in with the "shipping-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/shipping" as "shipment" using:
      | displayName          | cartMinimum | cartMaximum | currentPrice | shipmentTime |
      | Automated Shipping B | 50          | 100         | 200          | 120          |
    Then there should be a 200 response from the "shipment" request that contains:
      | _id       | displayName          | cartMinimum | cartMaximum | currentPrice | shipmentTime | created   | updated   |
      | OBJECT_ID | Automated Shipping B | 50          | 100         | 200          | 120          | DATE_TIME | DATE_TIME |
