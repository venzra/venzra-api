@Store @Category @CategoryRetrieve
Feature: Retrieve information for a category

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName             | status |
      | Category Retrieve One | ACTIVE |
      | Category Retrieve Two | ACTIVE |
    And there are the following "images" records in the database
      | subscription               | name                     | usage     | size |
      | {{ subscriptions[1]._id }} | CategoryRetrieve Image A | feature   | 1024 |
      | {{ subscriptions[1]._id }} | CategoryRetrieve Image B | promotion | 1024 |
    And there are the following "products" records in the database in series
      | subscription               | code            | displayName         | description           | featureImage        | promotionalImage    | currentPrice | status   |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-001 | Category Retrieve A | Automated Description | {{ images[1]._id }} | {{ images[2]._id }} | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-002 | Category Retrieve B | Automated Description | {{ images[1]._id }} | {{ images[2]._id }} | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-003 | Category Retrieve C | Automated Description | {{ images[1]._id }} | {{ images[2]._id }} | 999          | INACTIVE |
    And there are the following "categories" records in the database in series
      | subscription               | name                | description           | primary | featureImage        | products                                           |
      | {{ subscriptions[1]._id }} | Category Retrieve A | Automated description | true    | {{ images[1]._id }} | ["{{ products[1]._id }}", "{{ products[2]._id }}"] |
      | {{ subscriptions[1]._id }} | Category Retrieve B | Automated description | false   | {{ images[1]._id }} | ["{{ products[1]._id }}"]                          |
      | {{ subscriptions[1]._id }} | Category Retrieve C | Automated description | false   | {{ images[1]._id }} | ["{{ products[3]._id }}"]                          |
      | {{ subscriptions[1]._id }} | Category Retrieve D | Automated description | false   | {{ images[1]._id }} |                                                    |
      | {{ subscriptions[2]._id }} | Category Retrieve A | Automated description | false   | {{ images[1]._id }} |                                                    |
    And the following "categories" records are updated in the database
      | _id                     | parent                  | children                                               |
      | {{ categories[2]._id }} | null                    | ["{{ categories[3]._id }}", "{{ categories[4]._id }}"] |
      | {{ categories[3]._id }} | {{ categories[2]._id }} | []                                                     |
      | {{ categories[4]._id }} | {{ categories[2]._id }} | []                                                     |

  Scenario: Retrieval of a category contains correct data
    Given the request origin headers are set to "category-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/categories/{{ categories[1].slug }}" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug                | name                | description           | featureImage          | children |
      | OBJECT_ID | category-retrieve-a | Category Retrieve A | Automated description | OBJECT[_id,name,path] | ARRAY[0] |
    And the response path "featureImage" from the "category" request contains:
      | _id       | name                     | path                                                         |
      | OBJECT_ID | CategoryRetrieve Image A | {{ images[1].subscription }}/feature/{{ images[1]._id }}.jpg |

  Scenario: Retrieval of a category contains correct data
    Given the request origin headers are set to "category-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/categories/{{ categories[2].slug }}" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug                | name                | description           | featureImage          | children |
      | OBJECT_ID | category-retrieve-b | Category Retrieve B | Automated description | OBJECT[_id,name,path] | ARRAY[2] |
    And the response path "children" from the "category" request contains:
      | _id       | slug                | name                | featureImage          |
      | OBJECT_ID | category-retrieve-c | Category Retrieve C | OBJECT[_id,name,path] |
      | OBJECT_ID | category-retrieve-d | Category Retrieve D | OBJECT[_id,name,path] |

  Scenario: A category with only inactive products is returned
    Given the request origin headers are set to "category-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/categories/{{ categories[3].slug }}" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug                | name                | description           | featureImage          | parent                             | children |
      | OBJECT_ID | category-retrieve-c | Category Retrieve C | Automated description | OBJECT[_id,name,path] | OBJECT[_id,slug,name,featureImage] | ARRAY[0] |
    And the response path "parent" from the "category" request contains:
      | _id       | slug                | name                | featureImage          |
      | OBJECT_ID | category-retrieve-b | Category Retrieve B | OBJECT[_id,name,path] |

  Scenario: A category with no products is returned
    Given the request origin headers are set to "category-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/categories/{{ categories[4].slug }}" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | _id       | slug                | name                | description           | featureImage          | parent                             | children |
      | OBJECT_ID | category-retrieve-d | Category Retrieve D | Automated description | OBJECT[_id,name,path] | OBJECT[_id,slug,name,featureImage] | ARRAY[0] |

  Scenario: Another subscription user cannot retrieve a record that does not belong to them
    Given the request origin headers are set to "category-retrieve-two.venzra-test.io"
    When I make a GET request to the API endpoint "/store/categories/{{ categories[2].slug }}" as "category"
    Then the status returned from the "category" request should be a 404 error
