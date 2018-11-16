@Admin @Category @CategorySummary
Feature: Summary information for all categories

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                    | status |
      | Admin Category Summary One   | ACTIVE |
      | Admin Category Summary Two   | ACTIVE |
      | Admin Category Summary Three | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                              | password | status | subscription               |
      | category-summary-one@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | category-summary-two@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
      | category-summary-three@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[3]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                    | usage   | size |
      | {{ subscriptions[1]._id }} | CategorySummary Image A | feature | 1024 |
      | {{ subscriptions[1]._id }} | CategorySummary Image B | feature | 1024 |
    And there are the following "categories" records in the database in series
      | subscription               | name                 | description           | featureImage        | primary |
      | {{ subscriptions[1]._id }} | Category Summary A   | Automated description | {{ images[1]._id }} | true    |
      | {{ subscriptions[1]._id }} | Category Summary AA  | Automated description |                     | true    |
      | {{ subscriptions[1]._id }} | Category Summary AAA | Automated description | {{ images[2]._id }} | false   |
      | {{ subscriptions[1]._id }} | Category Summary B   | Automated description |                     | false   |
      | {{ subscriptions[1]._id }} | Category Summary C   | Automated description | {{ images[2]._id }} | false   |
      | {{ subscriptions[1]._id }} | Category Summary D   | Automated description |                     | true    |
      | {{ subscriptions[1]._id }} | Category Summary ABC | Automated description |                     | true    |
      | {{ subscriptions[2]._id }} | Category Summary A   | Automated description |                     | false   |
      | {{ subscriptions[2]._id }} | Category Summary B   | Automated description |                     | true    |
    And the following "categories" records are updated in the database
      | _id                     | parent                  | children                                               |
      | {{ categories[1]._id }} | null                    | ["{{ categories[3]._id }}", "{{ categories[4]._id }}"] |
      | {{ categories[3]._id }} | {{ categories[1]._id }} | []                                                     |
      | {{ categories[4]._id }} | {{ categories[1]._id }} | []                                                     |
      | {{ categories[5]._id }} | null                    | ["{{ categories[6]._id }}"]                            |
      | {{ categories[6]._id }} | {{ categories[5]._id }} | []                                                     |

  Scenario: Requesting a list of categories should return only records for that subscription (subscription one)
    Given I am logged in with the "category-summary-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories/summary" as "summary"
    Then there should be a 200 response from the "summary" request that contains:
      | list     |
      | ARRAY[4] |
    And the "summary" request that has a "list" field and row 1 contains:
      | _id       | name               | children |
      | OBJECT_ID | Category Summary A | ARRAY[2] |
    And the "summary" request that has a "list" field and row 2 contains:
      | _id       | name                | children |
      | OBJECT_ID | Category Summary AA | ARRAY[0] |
    And the "summary" request that has a "list" field and row 3 contains:
      | _id       | name                 | children |
      | OBJECT_ID | Category Summary ABC | ARRAY[0] |
    And the "summary" request that has a "list" field and row 4 contains:
      | _id       | name               | children |
      | OBJECT_ID | Category Summary C | ARRAY[1] |

  Scenario: A subscription with no categories will return empty summary data
    Given I am logged in with the "category-summary-three@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories/summary" as "summary"
    Then there should be a 200 response from the "summary" request that contains:
      | list     |
      | ARRAY[0] |
