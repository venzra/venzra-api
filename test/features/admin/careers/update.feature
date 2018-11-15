@Admin @Careers @CareersUpdate
Feature: Update careers information for display and modification

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                | status |
      | Admin Careers Update One | ACTIVE |
      | Admin Careers Update Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                          | password | status | subscription               |
      | careers-update-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | careers-update-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "careers" records in the database
      | position                  | description        | expires   | subscription               |
      | Careers Update Position A | Automated position | DATE(120) | {{ subscriptions[1]._id }} |
      | Careers Update Position B | Automated position | DATE(120) | {{ subscriptions[1]._id }} |
      | Careers Update Position C | Automated position | DATE(120) | {{ subscriptions[2]._id }} |

  Scenario: Sending an empty update request does not change any data
    Given I am logged in with the "careers-update-one@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/careers/{{ careers[1]._id }}" as "career"
    Then there should be a 200 response from the "career" request that contains:
      | _id       | position                  | description        | expires   | created   | updated   |
      | OBJECT_ID | Careers Update Position A | Automated position | DATE_TIME | DATE_TIME | DATE_TIME |

  Scenario: Update of careers correctly sets the new careers information
    Given I am logged in with the "careers-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/careers/{{ careers[1]._id }}" as "career" using:
      | op      | path        | value                           |
      | replace | position    | Careers Update Position Updated |
      | replace | description | Updated description             |
      | replace | expires     | DATE(720)                       |
    Then there should be a 200 response from the "career" request that contains:
      | _id       | position                        | description         | expires   | created   | updated   |
      | OBJECT_ID | Careers Update Position Updated | Updated description | DATE[720] | DATE_TIME | DATE_TIME |

  Scenario: It is not possible for a user of another subscription to alter a career that does not belong to them
    Given I am logged in with the "careers-update-two@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/careers/{{ careers[1]._id }}" as "career"
    Then the status returned from the "career" request should be a 404 error
