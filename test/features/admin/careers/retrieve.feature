@Admin @Careers @CareersRetrieve
Feature: Retrieve information for a careers position

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                  | status |
      | Admin Careers Retrieve One | ACTIVE |
      | Admin Careers Retrieve Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                            | password | status | subscription               |
      | careers-retrieve-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | careers-retrieve-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "careers" records in the database
      | position                    | description        | expires   | subscription               |
      | Careers Retrieve Position A | Automated position | DATE(120) | {{ subscriptions[1]._id }} |
      | Careers Retrieve Position B | Automated position | DATE(120) | {{ subscriptions[1]._id }} |
      | Careers Retrieve Position A | Automated position | DATE(120) | {{ subscriptions[2]._id }} |

  Scenario: Retrieval of a careers position contains correct data
    Given I am logged in with the "careers-retrieve-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/careers/{{ careers[1]._id }}" as "career"
    Then there should be a 200 response from the "career" request that contains:
      | _id       | position                    | description        | expires   | created   | updated   |
      | OBJECT_ID | Careers Retrieve Position A | Automated position | DATE_TIME | DATE_TIME | DATE_TIME |

  Scenario: Another subscription user cannot retrieve a record that does not belong to them
    Given I am logged in with the "careers-retrieve-two@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/careers/{{ careers[1]._id }}" as "career"
    Then the status returned from the "career" request should be a 404 error
