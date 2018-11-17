@Admin @Content @ContentRetrieve
Feature: Retrieve content information for display and modification

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                  | status |
      | Admin Content Retrieve One | ACTIVE |
      | Admin Content Retrieve Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                            | password | status | subscription               |
      | content-retrieve-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | content-retrieve-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "content" records in the database
      | subscription               | content                      | usage    |
      | {{ subscriptions[1]._id }} | Hello world about content    | about    |
      | {{ subscriptions[1]._id }} | Hello world careers content  | careers  |
      | {{ subscriptions[1]._id }} | Hello world contact content  | contact  |
      | {{ subscriptions[1]._id }} | Hello world location content | location |
      | {{ subscriptions[1]._id }} | Hello world terms content    | terms    |
      | {{ subscriptions[2]._id }} | Hello world about content    | about    |

  Scenario: Retrieval of a content information contains correct data
    Given I am logged in with the "content-retrieve-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/content/about" as "content"
    Then there should be a 200 response from the "content" request that contains:
      | _id       | content                   | usage | created   | updated   |
      | OBJECT_ID | Hello world about content | ABOUT | DATE_TIME | DATE_TIME |

  Scenario: Another subscription user cannot retrieve a record that does not belong to them, however gets a blank positive result
    Given I am logged in with the "content-retrieve-two@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/content/careers" as "content"
    Then there should be a 200 response from the "content" request that contains:
      |  |
      |  |
