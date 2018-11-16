@Admin @Category @CategoryRetrieve
Feature: Retrieve information for a category

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                   | status |
      | Admin Category Retrieve One | ACTIVE |
      | Admin Category Retrieve Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                             | password | status | subscription               |
      | category-retrieve-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | category-retrieve-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                     | usage     | size |
      | {{ subscriptions[1]._id }} | CategoryRetrieve Image A | promotion | 1024 |
      | {{ subscriptions[1]._id }} | CategoryRetrieve Image B | feature   | 1024 |
    And there are the following "products" records in the database in series
      | subscription               | code            | displayName         | description           | promotionalImage    | currentPrice | status |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-001 | Category Retrieve A | Automated Description | {{ images[1]._id }} | 9            | ACTIVE |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-002 | Category Retrieve B | Automated Description | {{ images[1]._id }} | 99           | ACTIVE |
    And there are the following "categories" records in the database in series
      | subscription               | name                | description           | featureImage        | primary | products                                           |
      | {{ subscriptions[1]._id }} | Category Retrieve A | Automated description | {{ images[2]._id }} | true    | ["{{ products[1]._id }}", "{{ products[2]._id }}"] |
      | {{ subscriptions[1]._id }} | Category Retrieve B | Automated description | NULL                | false   | ["{{ products[1]._id }}"]                          |
      | {{ subscriptions[1]._id }} | Category Retrieve C | Automated description | NULL                | false   |                                                    |
      | {{ subscriptions[2]._id }} | Category Retrieve A | Automated description | NULL                | false   |                                                    |
    And the following "categories" records are updated in the database
      | _id                     | parent                  | children                    |
      | {{ categories[2]._id }} | null                    | ["{{ categories[3]._id }}"] |
      | {{ categories[3]._id }} | {{ categories[2]._id }} | []                          |

  Scenario: Retrieval of a category contains correct data
    Given I am logged in with the "category-retrieve-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug                | name                | description           | featureImage                                                                                | primary | children | products | created   | updated   |
      | OBJECT_ID | category-retrieve-a | Category Retrieve A | Automated description | https://images.venzra-test.com/{{ images[1].subscription }}/feature/{{ images[2]._id }}.jpg | true    | ARRAY[0] | ARRAY[2] | DATE_TIME | DATE_TIME |
    And the response path "products" from the "category" request contains:
      | _id       | code            | displayName         | promotionalImage                                                                              | status | created   | updated   |
      | OBJECT_ID | RETRIEVE-01-001 | Category Retrieve A | https://images.venzra-test.com/{{ images[1].subscription }}/promotion/{{ images[1]._id }}.jpg | ACTIVE | DATE_TIME | DATE_TIME |
      | OBJECT_ID | RETRIEVE-01-002 | Category Retrieve B | https://images.venzra-test.com/{{ images[1].subscription }}/promotion/{{ images[1]._id }}.jpg | ACTIVE | DATE_TIME | DATE_TIME |

  Scenario: Retrieval of a category contains correct data
    Given I am logged in with the "category-retrieve-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[2]._id }}" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug                | name                | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-retrieve-b | Category Retrieve B | Automated description | false   | ARRAY[1] | ARRAY[1] | DATE_TIME | DATE_TIME |
    And the response path "children" from the "category" request contains:
      | _id       | slug                | name                | primary | created   | updated   |
      | OBJECT_ID | category-retrieve-c | Category Retrieve C | false   | DATE_TIME | DATE_TIME |

  Scenario: Retrieval of a category contains correct data
    Given I am logged in with the "category-retrieve-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[3]._id }}" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug                | name                | description           | primary | parent | children | products | created   | updated   |
      | OBJECT_ID | category-retrieve-c | Category Retrieve C | Automated description | false   | OBJECT | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |
    And the response path "parent" from the "category" request contains:
      | _id       | slug                | name                | primary | created   | updated   |
      | OBJECT_ID | category-retrieve-b | Category Retrieve B | false   | DATE_TIME | DATE_TIME |

  Scenario: Another subscription user cannot retrieve a record that does not belong to them
    Given I am logged in with the "category-retrieve-two@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "category"
    Then the status returned from the "category" request should be a 404 error
