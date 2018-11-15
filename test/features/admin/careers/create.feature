@Admin @Careers @CareersCreate
Feature: Creation of a new career entry

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                | status |
      | Admin Careers Create One | ACTIVE |
      | Admin Careers Create Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                          | password | status | subscription               |
      | careers-create-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | careers-create-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |

  Scenario: An empty request to create a careers record fails validation
    Given I am logged in with the "careers-create-one@venzra-test.io" admin account
    When I make an empty POST request to the API endpoint "/admin/careers" as "career"
    Then there should be a 400 error from the "career" request that contains:
      | message           | detail                                                            |
      | Validation failed | ["position required", "description required", "expires required"] |

  Scenario: A valid request to create a new careers record is successful with defaults entered when not set
    Given I am logged in with the "careers-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/careers" as "career" using:
      | position                  | description        | expires   |
      | Careers Create Position A | Automated position | DATE(120) |
    Then there should be a 200 response from the "career" request that contains:
      | _id       | position                  | description        | expires   | created   | updated   |
      | OBJECT_ID | Careers Create Position A | Automated position | DATE[120] | DATE_TIME | DATE_TIME |
