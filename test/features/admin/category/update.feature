@Admin @Category @CategoryUpdate
Feature: Update information about a new category

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | status |
      | Admin Category Update One | ACTIVE |
      | Admin Category Update Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | category-update-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | category-update-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                   | usage   | size |
      | {{ subscriptions[1]._id }} | CategoryUpdate Image A | feature | 1024 |
    And there are the following "categories" records in the database in series
      | subscription               | name              | description           |
      | {{ subscriptions[1]._id }} | Category Update A | Automated description |
      | {{ subscriptions[1]._id }} | Category Update B | Automated description |
      | {{ subscriptions[1]._id }} | Category Update C | Automated description |
      | {{ subscriptions[2]._id }} | Category Update A | Automated description |
    And the following "categories" records are updated in the database
      | _id                     | parent                  | children                    |
      | {{ categories[2]._id }} | null                    | ["{{ categories[3]._id }}"] |
      | {{ categories[3]._id }} | {{ categories[2]._id }} | []                          |

  Scenario: If no update information is provided then the request is ignored
    Given I am logged in with the "category-update-one@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-update-a | Category Update A | Automated description | false   | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |

  Scenario: Attempting to update a category that does not belong to the account subscription is rejected
    Given I am logged in with the "category-update-two@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "category"
    Then the status returned from the "category" request should be a 404 error

  Scenario: Update category information with duplicate value will not change any information
    Given I am logged in with the "category-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "category" using:
      | op      | path        | value               |
      | replace | description | Updated description |
      | replace | name        | Category Update B   |
    Then there should be a 400 response from the "category" request that contains:
      | message               | detail |
      | Record already exists | []     |
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-update-a | Category Update A | Automated description | false   | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |

  Scenario: Update category information with values provided which can be altered
    Given I am logged in with the "category-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "category" using:
      | op      | path        | value                 |
      | replace | name        | Category Update PATCH |
      | replace | description | Updated description   |
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug                  | name                  | description         | primary | children | products | created   | updated   |
      | OBJECT_ID | category-update-patch | Category Update PATCH | Updated description | false   | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |

  Scenario: A category with children cannot be assigned a parent however can be marked primary
    Given I am logged in with the "category-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/categories/{{ categories[2]._id }}" as "category" using:
      | op      | path    | value                   |
      | replace | primary | true                    |
      | replace | parent  | {{ categories[2]._id }} |
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-update-b | Category Update B | Automated description | true    | ARRAY[1] | ARRAY[0] | DATE_TIME | DATE_TIME |

  Scenario: A subcategory can be given a different parent, however cannot by made primary
    Given I am logged in with the "category-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/categories/{{ categories[3]._id }}" as "category" using:
      | op      | path    | value                   |
      | replace | primary | true                    |
      | replace | parent  | {{ categories[1]._id }} |
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug              | name              | description           | primary | parent | children | products | created   | updated   |
      | OBJECT_ID | category-update-c | Category Update C | Automated description | false   | OBJECT | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |
    And the response path "parent" from the "category" request contains:
      | _id       | slug                  | name                  | primary | created   | updated   |
      | OBJECT_ID | category-update-patch | Category Update PATCH | false   | DATE_TIME | DATE_TIME |
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug                  | name                  | description         | primary | children | products | created   | updated   |
      | OBJECT_ID | category-update-patch | Category Update PATCH | Updated description | false   | ARRAY[1] | ARRAY[0] | DATE_TIME | DATE_TIME |
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[2]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-update-b | Category Update B | Automated description | true    | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |

  Scenario: Attempting to assign a subcategory to a parent belonging to another subscription fails to update changes
    Given I am logged in with the "category-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/categories/{{ categories[3]._id }}" as "category" using:
      | op      | path   | value                   |
      | replace | name   | Category Update PATCH   |
      | replace | parent | {{ categories[4]._id }} |
    Then the status returned from the "category" request should be a 404 error
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[3]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug              | name              | description           | primary | parent | children | products | created   | updated   |
      | OBJECT_ID | category-update-c | Category Update C | Automated description | false   | OBJECT | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |
    And the response path "parent" from the "check" request contains:
      | _id       | slug                  | name                  | primary | created   | updated   |
      | OBJECT_ID | category-update-patch | Category Update PATCH | false   | DATE_TIME | DATE_TIME |
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug                  | name                  | description         | primary | children | products | created   | updated   |
      | OBJECT_ID | category-update-patch | Category Update PATCH | Updated description | false   | ARRAY[1] | ARRAY[0] | DATE_TIME | DATE_TIME |
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[2]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-update-b | Category Update B | Automated description | true    | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |
