@Admin @Locations @LocationsRemove
Feature: Remove a location from the database

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                  | status |
      | Admin Locations Remove One | ACTIVE |
      | Admin Locations Remove Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                            | password | status | subscription               |
      | locations-remove-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | locations-remove-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                   | usage   | size |
      | {{ subscriptions[1]._id }} | LocationRemove Image A | feature | 1024 |
    And there are the following "locations" records in the database
      | displayName        | description        | address                                                                                                                | featureImage        | subscription               |
      | Locations Remove A | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | {{ subscriptions[1]._id }} |
      | Locations Remove B | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | {{ subscriptions[1]._id }} |
      | Locations Remove A | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | {{ subscriptions[2]._id }} |

  Scenario: Removal of a location occurs successfully
    Given I am logged in with the "locations-remove-one@venzra-test.io" admin account
    When I make a DELETE request to the API endpoint "/admin/locations/{{ locations[1]._id }}" as "location"
    Then the status returned from the "location" request should be 202
    When I make a GET request to the API endpoint "/admin/locations/{{ locations[1]._id }}" as "check"
    Then the status returned from the "check" request should be a 404 error

  Scenario: It is not possible to remove a record for another subscription
    Given I am logged in with the "locations-remove-two@venzra-test.io" admin account
    When I make a DELETE request to the API endpoint "/admin/locations/{{ locations[2]._id }}" as "location"
    Then the status returned from the "location" request should be a 404 error
