@Admin @Category @CategoryRemove
Feature: Remove a category from the database

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | status |
      | Admin Category Remove One | ACTIVE |
      | Admin Category Remove Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | category-remove-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | category-remove-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                   | usage   | size |
      | {{ subscriptions[1]._id }} | CategoryRemove Image A | feature | 1024 |
    And there are the following "categories" records in the database in series
      | subscription               | name              | description           | primary |
      | {{ subscriptions[1]._id }} | Category Remove A | Automated description | true    |
      | {{ subscriptions[1]._id }} | Category Remove B | Automated description | false   |
      | {{ subscriptions[1]._id }} | Category Remove C | Automated description | false   |
      | {{ subscriptions[1]._id }} | Category Remove D | Automated description | false   |
      | {{ subscriptions[1]._id }} | Category Remove E | Automated description | false   |
      | {{ subscriptions[1]._id }} | Category Remove F | Automated description | false   |
      | {{ subscriptions[2]._id }} | Category Remove A | Automated description | false   |
    And the following "categories" records are updated in the database
      | _id                     | parent                  | children                                               |
      | {{ categories[2]._id }} | null                    | ["{{ categories[3]._id }}"]                            |
      | {{ categories[3]._id }} | {{ categories[2]._id }} | []                                                     |
      | {{ categories[4]._id }} | null                    | ["{{ categories[5]._id }}", "{{ categories[6]._id }}"] |
      | {{ categories[5]._id }} | {{ categories[4]._id }} | []                                                     |
      | {{ categories[6]._id }} | {{ categories[4]._id }} | []                                                     |

  Scenario: Removal of a category occurs successfully
    Given I am logged in with the "category-remove-one@venzra-test.io" admin account
    When I make a DELETE request to the API endpoint "/admin/categories/{{ categories[1]._id }}" as "category"
    Then the status returned from the "category" request should be 202

  Scenario: It is not possible to remove a record for another subscription
    Given I am logged in with the "category-remove-two@venzra-test.io" admin account
    When I make a DELETE request to the API endpoint "/admin/categories/{{ categories[2]._id }}" as "category"
    Then the status returned from the "category" request should be a 404 error

  Scenario: Removal of a parent category updates children to remove association
    Given I am logged in with the "category-remove-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[3]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug              | name              | description           | primary | parent | children | products | created   | updated   |
      | OBJECT_ID | category-remove-c | Category Remove C | Automated description | false   | OBJECT | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |
    When I make a DELETE request to the API endpoint "/admin/categories/{{ categories[2]._id }}" as "category"
    Then the status returned from the "category" request should be 202
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[3]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-remove-c | Category Remove C | Automated description | false   | ARRAY[0] | ARRAY[0] | DATE_TIME | DATE_TIME |

  Scenario: Removal of a child category updates parent to remove association
    Given I am logged in with the "category-remove-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[4]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-remove-d | Category Remove D | Automated description | false   | ARRAY[2] | ARRAY[0] | DATE_TIME | DATE_TIME |
    When I make a DELETE request to the API endpoint "/admin/categories/{{ categories[5]._id }}" as "category"
    Then the status returned from the "category" request should be 202
    When I make a GET request to the API endpoint "/admin/categories/{{ categories[4]._id }}" as "check"
    Then there should be a 200 response from the "check" request that contains:
      | _id       | slug              | name              | description           | primary | children | products | created   | updated   |
      | OBJECT_ID | category-remove-d | Category Remove D | Automated description | false   | ARRAY[1] | ARRAY[0] | DATE_TIME | DATE_TIME |
    And the response path "children" from the "check" request contains:
      | _id       | slug              | name              | primary | created   | updated   |
      | OBJECT_ID | category-remove-f | Category Remove F | false   | DATE_TIME | DATE_TIME |
