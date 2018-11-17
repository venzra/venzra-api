@Admin @Content @ContentUpdate
Feature: Retrieve content information for display and modification

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                | status |
      | Admin Content Update One | ACTIVE |
      | Admin Content Update Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                          | password | status | subscription               |
      | content-update-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | content-update-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "content" records in the database
      | subscription               | content                   | usage |
      | {{ subscriptions[1]._id }} | Hello world about content | about |

  Scenario: Updating content that does no exist will create a new record for that subscription
    Given I am logged in with the "content-update-two@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/content/about" as "content" using:
      | op      | path    | value       |
      | replace | content | New content |
    Then there should be a 200 response from the "content" request that contains:
      | _id       | content     | usage | created   | updated   |
      | OBJECT_ID | New content | ABOUT | DATE_TIME | DATE_TIME |
    When I am logged in with the "content-update-one@venzra-test.io" admin account
    And I make a GET request to the API endpoint "/admin/content/about" as "content"
    Then there should be a 200 response from the "content" request that contains:
      | _id       | content                   | usage | created   | updated   |
      | OBJECT_ID | Hello world about content | ABOUT | DATE_TIME | DATE_TIME |

  Scenario: Sending an empty update request does not change any data
    Given I am logged in with the "content-update-one@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/content/about" as "content"
    Then there should be a 200 response from the "content" request that contains:
      | _id       | content                   | usage | created   | updated   |
      | OBJECT_ID | Hello world about content | ABOUT | DATE_TIME | DATE_TIME |

  Scenario: Update of content correctly sets the new content information
    Given I am logged in with the "content-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/content/about" as "content" using:
      | op      | path    | value           |
      | replace | content | Updated content |
    Then there should be a 200 response from the "content" request that contains:
      | _id       | content         | usage | created   | updated   |
      | OBJECT_ID | Updated content | ABOUT | DATE_TIME | DATE_TIME |
