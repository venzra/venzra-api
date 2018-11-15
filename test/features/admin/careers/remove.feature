@Admin @Careers @CareersRemove
Feature: Remove a career position from the database

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                | status |
      | Admin Careers Remove One | ACTIVE |
      | Admin Careers Remove Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                          | password | status | subscription               |
      | careers-remove-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | careers-remove-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "careers" records in the database
      | position                  | description        | expires   | subscription               |
      | Careers Remove Position A | Automated position | DATE(120) | {{ subscriptions[1]._id }} |
      | Careers Remove Position B | Automated position | DATE(120) | {{ subscriptions[1]._id }} |
      | Careers Remove Position A | Automated position | DATE(120) | {{ subscriptions[2]._id }} |

  Scenario: Removal of a careers position occurs successfully
    Given I am logged in with the "careers-remove-one@venzra-test.io" admin account
    When I make a DELETE request to the API endpoint "/admin/careers/{{ careers[1]._id }}" as "career"
    Then the status returned from the "career" request should be 202
    When I make a GET request to the API endpoint "/api/careers/{{ careers[1]._id }}" as "check"
    Then the status returned from the "check" request should be a 404 error

  Scenario: It is not possible to remove a record for another subscription
    Given I am logged in with the "careers-remove-two@venzra-test.io" admin account
    When I make a DELETE request to the API endpoint "/admin/careers/{{ careers[2]._id }}" as "career"
    Then the status returned from the "career" request should be a 404 error
