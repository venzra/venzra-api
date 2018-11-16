@Admin @Category @CategoryCreate
Feature: Creation of a new category

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | status |
      | Admin Category Create One | ACTIVE |
      | Admin Category Create Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | category-create-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | category-create-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                   | usage   | size |
      | {{ subscriptions[1]._id }} | CategoryCreate Image A | feature | 1024 |
    And there are the following "categories" records in the database in series
      | subscription               | name              | description           |
      | {{ subscriptions[1]._id }} | Category Create A | Automated description |

  Scenario: An empty request to create a category fails validation
    Given I am logged in with the "category-create-one@venzra-test.io" admin account
    When I make an empty POST request to the API endpoint "/admin/categories" as "category"
    Then there should be a 400 error from the "category" request that contains:
      | message           | detail                                     |
      | Validation failed | ["name required",  "description required"] |

  Scenario: If the category already exists then the request should be rejected (based on slugified name)
    Given I am logged in with the "category-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/categories" as "category" using:
      | name                     | description           |
      | {{ categories[1].name }} | Automated Description |
    Then there should be a 400 response from the "category" request that contains:
      | message               | detail |
      | Record already exists | []     |

  Scenario: A valid request to create a new category record is successful
    Given I am logged in with the "category-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/categories" as "category" using:
      | name              | description           |
      | Category Create B | Automated description |
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-create-b | Category Create B | Automated description | false   | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |

  Scenario: A valid request to create a new category record is successful (when setting to primary parent is ignored)
    Given I am logged in with the "category-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/categories" as "category" using:
      | parent                  | name              | description           | primary |
      | {{ categories[1]._id }} | Category Create C | Automated description | true    |
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-create-c | Category Create C | Automated description | true    | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |

  Scenario: A valid request to create a subcategory record is successful
    Given I am logged in with the "category-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/categories" as "category" using:
      | parent                  | name              | description           | featureImage        |
      | {{ categories[1]._id }} | Category Create D | Automated description | {{ images[1]._id }} |
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug              | name              | description           | featureImage                                                                                | primary | parent | children | products | created   | updated   |
      | OBJECT_ID | category-create-d | Category Create D | Automated description | https://images.venzra-test.com/{{ images[1].subscription }}/feature/{{ images[1]._id }}.jpg | false   | OBJECT | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-create-a | Category Create A | Automated description | false   | ARRAY[1] | ARRAY[0] | DATE_TIME | DATE_TIME |

  Scenario: It should not be possible for another account to reference a category that belongs to another account
    Given I am logged in with the "category-create-two@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/categories" as "category" using:
      | parent                  | name                     | description           |
      | {{ categories[1]._id }} | {{ categories[1].name }} | Automated description |
    Then the status returned from the "category" request should be a 404 error

  Scenario: An account linked to another subscription can use the same category name already used by a different subscription
    Given I am logged in with the "category-create-two@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/categories" as "category" using:
      | name                     | description           |
      | {{ categories[1].name }} | Automated description |
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-create-a | Category Create A | Automated description | false   | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |
