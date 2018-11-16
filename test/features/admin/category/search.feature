@Admin @Category @CategorySearch
Feature: Search information for a category

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                   | status |
      | Admin Category Search One   | ACTIVE |
      | Admin Category Search Two   | ACTIVE |
      | Admin Category Search Three | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                             | password | status | subscription               |
      | category-search-one@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | category-search-two@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
      | category-search-three@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[3]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                   | usage   | size |
      | {{ subscriptions[1]._id }} | CategorySearch Image A | feature | 1024 |
      | {{ subscriptions[1]._id }} | CategorySearch Image B | feature | 1024 |
    And there are the following "categories" records in the database in series
      | subscription               | name                | description           | featureImage        | primary |
      | {{ subscriptions[1]._id }} | Category Search A   | Automated description | {{ images[1]._id }} | true    |
      | {{ subscriptions[1]._id }} | Category Search AA  | Automated description |                     | true    |
      | {{ subscriptions[1]._id }} | Category Search AAA | Automated description | {{ images[2]._id }} | false   |
      | {{ subscriptions[1]._id }} | Category Search B   | Automated description |                     | false   |
      | {{ subscriptions[1]._id }} | Category Search C   | Automated description | {{ images[2]._id }} | false   |
      | {{ subscriptions[1]._id }} | Category Search D   | Automated description |                     | true    |
      | {{ subscriptions[1]._id }} | Category Search ABC | Automated description |                     | true    |
      | {{ subscriptions[2]._id }} | Category Search A   | Automated description |                     | false   |
      | {{ subscriptions[2]._id }} | Category Search B   | Automated description |                     | true    |
    And the following "categories" records are updated in the database
      | _id                     | parent                  | children                                               |
      | {{ categories[1]._id }} | null                    | ["{{ categories[3]._id }}", "{{ categories[4]._id }}"] |
      | {{ categories[3]._id }} | {{ categories[1]._id }} | []                                                     |
      | {{ categories[4]._id }} | {{ categories[1]._id }} | []                                                     |

  Scenario: Requesting a list of categories should return only records for that subscription (subscription one)
    Given I am logged in with the "category-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[7] | 7     | 0    | 20    |
    And the "category" request that has a "list" field and row 1 contains:
      | _id       | slug              | name              | featureImage                | primary | children | products | created   |
      | OBJECT_ID | category-search-a | Category Search A | OBJECT[_id,name,usage,path] | true    | 2        | 0        | DATE_TIME |
    And the "category" request that has a "list" field and row 2 contains:
      | _id       | slug               | name               | primary | children | products | created   |
      | OBJECT_ID | category-search-aa | Category Search AA | true    | 0        | 0        | DATE_TIME |

  Scenario: Requesting a list of categories should return only records for that subscription (subscription two)
    Given I am logged in with the "category-search-two@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[2] | 2     | 0    | 20    |
    And the "category" request that has a "list" field and row 1 contains:
      | _id       | slug              | name              | primary | children | products | created   |
      | OBJECT_ID | category-search-a | Category Search A | false   | 0        | 0        | DATE_TIME |

  Scenario: Requesting a list of categories adheres to pagination values for skip and limit
    Given I am logged in with the "category-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories?skip=3&limit=4" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[4] | 7     | 3    | 4     |
    And the "category" request that has a "list" field and row 1 contains:
      | _id       | slug                | name                | primary | children | products | created   |
      | OBJECT_ID | category-search-abc | Category Search ABC | true    | 0        | 0        | DATE_TIME |

  Scenario: Filtering category results by name returns based on partial matching
    Given I am logged in with the "category-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories?search=Search A" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[4] | 4     | 0    | 20    |
    And the response from the "category" request has a "list" that contains rows:
      | _id                     | name                |
      | {{ categories[1]._id }} | Category Search A   |
      | {{ categories[2]._id }} | Category Search AA  |
      | {{ categories[3]._id }} | Category Search AAA |
      | {{ categories[7]._id }} | Category Search ABC |

  Scenario: Filtering category results to only records that are "parent" entries
    Given I am logged in with the "category-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories?parent=true" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[5] | 5     | 0    | 20    |
    And the "category" request that has a "list" field and row 1 contains:
      | _id       | slug              | name              | featureImage                | primary | children | products | created   |
      | OBJECT_ID | category-search-a | Category Search A | OBJECT[_id,name,usage,path] | true    | 2        | 0        | DATE_TIME |

  Scenario: Sorting category results in reverse
    Given I am logged in with the "category-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories?direction=desc" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[7] | 7     | 0    | 20    |
    And the response from the "category" request has a "list" that contains rows:
      | _id                     | name                |
      | {{ categories[6]._id }} | Category Search D   |
      | {{ categories[5]._id }} | Category Search C   |
      | {{ categories[4]._id }} | Category Search B   |
      | {{ categories[7]._id }} | Category Search ABC |

  Scenario: Sorting category results by another column than the default
    Given I am logged in with the "category-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories?sort=created" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[7] | 7     | 0    | 20    |
    And the response from the "category" request has a "list" that contains rows:
      | _id                     | name                |
      | {{ categories[1]._id }} | Category Search A   |
      | {{ categories[2]._id }} | Category Search AA  |
      | {{ categories[3]._id }} | Category Search AAA |
      | {{ categories[4]._id }} | Category Search B   |

  Scenario: Sorting category results by another column than the default
    Given I am logged in with the "category-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories?sort=created&direction=desc" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[7] | 7     | 0    | 20    |
    And the response from the "category" request has a "list" that contains rows:
      | _id                     | name                |
      | {{ categories[7]._id }} | Category Search ABC |
      | {{ categories[6]._id }} | Category Search D   |
      | {{ categories[5]._id }} | Category Search C   |
      | {{ categories[4]._id }} | Category Search B   |

  Scenario: Requesting a list of categories should return no results when there are no categories (subscription three)
    Given I am logged in with the "category-search-three@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[0] | 0     | 0    | 20    |
