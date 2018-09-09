@Store @Category @CategorySummary
Feature: Summary information for all categories

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName              | status |
      | Category Summary One   | ACTIVE |
      | Category Summary Two   | ACTIVE |
      | Category Summary Three | ACTIVE |
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
    Given the request origin headers are set to "category-summary-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/categories" as "summary"
    Then there should be a 200 response from the "summary" request that contains:
      | list     |
      | ARRAY[4] |
    And the "summary" request that has a "list" field and row 1 contains:
      | _id       | slug               | name               | featureImage        | children |
      | OBJECT_ID | category-summary-a | Category Summary A | {{ images[1]._id }} | ARRAY[2] |
    And the "summary" request that has a "list" field and row 2 contains:
      | _id       | slug                | name                | children |
      | OBJECT_ID | category-summary-aa | Category Summary AA | ARRAY[0] |
    And the "summary" request that has a "list" field and row 3 contains:
      | _id       | slug                 | name                 | children |
      | OBJECT_ID | category-summary-abc | Category Summary ABC | ARRAY[0] |
    And the "summary" request that has a "list" field and row 4 contains:
      | _id       | slug               | name               | featureImage        | children |
      | OBJECT_ID | category-summary-c | Category Summary C | {{ images[2]._id }} | ARRAY[1] |

  Scenario: Requesting a list of categories supports filtering by primary
    Given the request origin headers are set to "category-summary-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/categories?primary=true" as "summary"
    Then there should be a 200 response from the "summary" request that contains:
      | list     |
      | ARRAY[3] |
    And the response from the "summary" request has a "list" that contains rows:
      | name                 |
      | Category Summary A   |
      | Category Summary AA  |
      | Category Summary ABC |

  Scenario: A subscription with no categories will return empty summary data
    Given the request origin headers are set to "category-summary-three.venzra-test.io"
    When I make a GET request to the API endpoint "/store/categories" as "summary"
    Then there should be a 200 response from the "summary" request that contains:
      | list     |
      | ARRAY[0] |
