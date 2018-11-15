@Store @Content @ContentRetrieve
Feature: Retrieval of content for a particular page

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                  | status |
      | Store Content Retrieve One | ACTIVE |
      | Store Content Retrieve Two | ACTIVE |
    And there are the following "content" records in the database
      | subscription               | content                | usage   |
      | {{ subscriptions[1]._id }} | Automated page content | CONTACT |

  Scenario: Attempting to retrieve an content that has not been created
    Given the request origin headers are set to "store-content-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/content/location" as "response"
    Then the status returned from the "response" request should be a 404 error

  Scenario: Successful retrieval of a record will give a result
    Given the request origin headers are set to "store-content-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/content/contact" as "response"
    Then there should be a 200 response from the "response" request that contains:
      | _id                  | content                |
      | {{ content[1]._id }} | Automated page content |

  Scenario: A subscription without the requested content page will return a 404 error
    Given the request origin headers are set to "store-content-retrieve-two.venzra-test.io"
    When I make a GET request to the API endpoint "/store/content/contact" as "response"
    Then the status returned from the "response" request should be a 404 error

  Scenario: There is a default terms and conditions page returned even when not in the database
    Given the request origin headers are set to "store-content-retrieve-two.venzra-test.io"
    When I make a GET request to the API endpoint "/store/content/terms" as "response"
    Then there should be a 200 response from the "response" request that contains:
      | content |
      | STRING  |
