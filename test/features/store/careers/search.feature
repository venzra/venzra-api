@Store @Careers @CareersSearch
Feature: Searching of available career positions

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName            | status |
      | Careers Search One   | ACTIVE |
      | Careers Search Two   | ACTIVE |
      | Careers Search Three | ACTIVE |
    And there are the following "careers" records in the database
      | position                    | description        | expires    | subscription               |
      | Careers Search Position A   | Automated position | DATE(120)  | {{ subscriptions[1]._id }} |
      | Careers Search Position AA  | Automated position | DATE(0)    | {{ subscriptions[1]._id }} |
      | Careers Search Position AAA | Automated position | DATE(-120) | {{ subscriptions[1]._id }} |
      | Careers Search Position B   | Automated position | DATE(120)  | {{ subscriptions[1]._id }} |
      | Careers Search Position C   | Automated position | DATE(240)  | {{ subscriptions[1]._id }} |
      | Careers Search Position D   | Automated position | DATE(720)  | {{ subscriptions[1]._id }} |
      | Careers Search Position A   | Automated position | DATE(240)  | {{ subscriptions[2]._id }} |
      | Careers Search Position B   | Automated position | DATE(120)  | {{ subscriptions[2]._id }} |

  Scenario: Requesting a list of career positions should return only records for that subscription
    Given the request origin headers are set to "careers-search-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/careers" as "career"
    Then there should be a 200 response from the "career" request that contains:
      | list     | total |
      | ARRAY[5] | 5     |
    And the response from the "career" request has a "list" that contains rows:
      | _id                  | position                    | description        | expires    |
      | {{ careers[2]._id }} | Careers Search Position AA  | Automated position | DATE[0]    |
      | {{ careers[1]._id }} | Careers Search Position A   | Automated position | DATE[120]  |
      | {{ careers[4]._id }} | Careers Search Position B   | Automated position | DATE[120]  |
      | {{ careers[5]._id }} | Careers Search Position C   | Automated position | DATE[240]  |
      | {{ careers[6]._id }} | Careers Search Position D   | Automated position | DATE[720]  |

  Scenario: Requesting a list of career positions should be empty when there are none for that subscription
    Given the request origin headers are set to "careers-search-three.venzra-test.io"
    When I make a GET request to the API endpoint "/store/careers" as "location"
    Then there should be a 200 response from the "location" request that contains:
      | list     | total |
      | ARRAY[0] | 0     |
