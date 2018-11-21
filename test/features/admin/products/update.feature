@Admin @Products @ProductsUpdate
Feature: Updating product information

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                | strapline                    |
      | Admin Product Update One | Automated subscription entry |
      | Admin Product Update Two | Automated subscription entry |
    And there are the following "accounts" records in the database
      | identity                          | password | status | subscription               |
      | product-update-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | product-update-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "categories" records in the database
      | subscription               | name              | description           | primary |
      | {{ subscriptions[1]._id }} | Products Update A | Automated description | true    |
      | {{ subscriptions[1]._id }} | Products Update B | Automated description | false   |
      | {{ subscriptions[1]._id }} | Products Update C | Automated description | false   |
      | {{ subscriptions[1]._id }} | Products Update D | Automated description | false   |
      | {{ subscriptions[2]._id }} | Products Update A | Automated description | false   |
    And the following "categories" records are updated in the database
      | _id                     | parent                  | children                                                                          |
      | {{ categories[1]._id }} | null                    | ["{{ categories[2]._id }}", "{{ categories[3]._id }}", "{{ categories[4]._id }}"] |
      | {{ categories[2]._id }} | {{ categories[1]._id }} | []                                                                                |
      | {{ categories[3]._id }} | {{ categories[1]._id }} | []                                                                                |
      | {{ categories[4]._id }} | {{ categories[1]._id }} | []                                                                                |
    And there are the following "images" records in the database
      | subscription               | name                   | usage     | size |
      | {{ subscriptions[1]._id }} | ProductsUpdate Image A | promotion | 1024 |
      | {{ subscriptions[1]._id }} | ProductsUpdate Image B | promotion | 4096 |
      | {{ subscriptions[2]._id }} | ProductsUpdate Image C | promotion | 2048 |
    And there are the following "products" records in the database
      | subscription               | code                | description           | displayName      | promotionalImage    | currentPrice |
      | {{ subscriptions[1]._id }} | PRODUCT-UPDATE-0001 | Automated Description | Product Update A | {{ images[2]._id }} | 9            |
      | {{ subscriptions[1]._id }} | PRODUCT-UPDATE-0002 | Automated Description | Product Update B | {{ images[2]._id }} | 99           |
      | {{ subscriptions[1]._id }} | PRODUCT-UPDATE-0003 | Automated Description | Product Update C | {{ images[1]._id }} | 999          |
      | {{ subscriptions[2]._id }} | PRODUCT-UPDATE-0004 | Automated Description | Product Update D | {{ images[3]._id }} | 9999         |

  Scenario: Attempting to update a product that does not belong to the account subscription is rejected
    Given I am logged in with the "product-update-two@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/products/{{ products[1]._id }}" as "product" using:
      | op      | path   | value  |
      | replace | status | ACTIVE |
    Then the status returned from the "product" request should be a 404 error

  Scenario: If no update information is provided then the request is ignored
    Given I am logged in with the "product-update-one@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/products/{{ products[1]._id }}" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | _id       | slug             | code                | displayName      | description           | promotionalImage                                                                            | previousPrice | currentPrice | categories | history  | status   | created   | updated   |
      | OBJECT_ID | product-update-a | PRODUCT-UPDATE-0001 | Product Update A | Automated Description | https://images.venzra-test.com/{{ subscriptions[1]._id }}/promotion/{{ images[2]._id }}.jpg | 0             | 9            | ARRAY[0]   | ARRAY[0] | INACTIVE | DATE_TIME | DATE_TIME |

  Scenario: Update product information with values provided which can be altered
    Given I am logged in with the "product-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/products/{{ products[1]._id }}" as "product" using:
      | op      | path             | value                |
      | replace | code             | PRODUCT-UPDATE-9999  |
      | replace | displayName      | Product Update PATCH |
      | replace | description      | Updated Description  |
      | replace | promotionalImage | {{ images[1]._id }}  |
      | replace | previousPrice    | 8                    |
      | replace | currentPrice     | 5                    |
      | replace | status           | ACTIVE               |
      | replace | slug             | updated-slug         |
    Then there should be a 200 response from the "product" request that contains:
      | _id       | slug                 | code                | displayName          | description         | promotionalImage                                                                            | previousPrice | currentPrice | categories | history  | status | created   | updated   |
      | OBJECT_ID | product-update-patch | PRODUCT-UPDATE-0001 | Product Update PATCH | Updated Description | https://images.venzra-test.com/{{ subscriptions[1]._id }}/promotion/{{ images[1]._id }}.jpg | 8             | 5            | ARRAY[0]   | ARRAY[6] | ACTIVE | DATE_TIME | DATE_TIME |
    And the "product" request that has a "history" field and row 1 contains:
      | account | field  | previous | next   | created   |
      | OBJECT  | status | INACTIVE | ACTIVE | DATE_TIME |
    And the "product" request that has a "history" field and row 2 contains:
      | account | field        | previous | next | created   |
      | OBJECT  | currentPrice | "9"      | "5"  | DATE_TIME |
    And the "product" request that has a "history" field and row 3 contains:
      | account | field         | previous | next | created   |
      | OBJECT  | previousPrice | "0"      | "8"  | DATE_TIME |
    And the "product" request that has a "history" field and row 4 contains:
      | account | field            | previous            | next                | created   |
      | OBJECT  | promotionalImage | {{ images[2]._id }} | {{ images[1]._id }} | DATE_TIME |
    And the "product" request that has a "history" field and row 5 contains:
      | account | field       | previous              | next                | created   |
      | OBJECT  | description | Automated Description | Updated Description | DATE_TIME |
    And the "product" request that has a "history" field and row 6 contains:
      | account | field       | previous         | next                 | created   |
      | OBJECT  | displayName | Product Update A | Product Update PATCH | DATE_TIME |

  Scenario: Assigning a single category vs an array is ignored
    Given I am logged in with the "product-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/products/{{ products[1]._id }}" as "product" using:
      | op      | path       | value                   |
      | replace | categories | {{ categories[2]._id }} |
    Then there should be a 200 response from the "product" request that contains:
      | _id       | slug                 | code                | displayName          | description         | promotionalImage                                                                            | previousPrice | currentPrice | categories | history  | status | created   | updated   |
      | OBJECT_ID | product-update-patch | PRODUCT-UPDATE-0001 | Product Update PATCH | Updated Description | https://images.venzra-test.com/{{ subscriptions[1]._id }}/promotion/{{ images[1]._id }}.jpg | 8             | 5            | ARRAY[0]   | ARRAY[6] | ACTIVE | DATE_TIME | DATE_TIME |

  Scenario: Assign categories to a product
    Given I am logged in with the "product-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/products/{{ products[1]._id }}" as "product" using:
      | op      | path       | value                                                                                                         |
      | replace | categories | ["{{ categories[1]._id }}", "{{ categories[2]._id }}", "{{ categories[3]._id }}", "{{ categories[4]._id }}" ] |
    Then there should be a 200 response from the "product" request that contains:
      | _id       | slug                 | code                | displayName          | description         | promotionalImage                                                                            | previousPrice | currentPrice | categories | history  | status | created   | updated   |
      | OBJECT_ID | product-update-patch | PRODUCT-UPDATE-0001 | Product Update PATCH | Updated Description | https://images.venzra-test.com/{{ subscriptions[1]._id }}/promotion/{{ images[1]._id }}.jpg | 8             | 5            | ARRAY[3]   | ARRAY[6] | ACTIVE | DATE_TIME | DATE_TIME |
    And the response path "categories" from the "product" request contains:
      | _id                     | name              | parent                                                            |
      | {{ categories[2]._id }} | Products Update B | { "_id": "{{ categories[1]._id }}", "name": "Products Update A" } |
      | {{ categories[3]._id }} | Products Update C | { "_id": "{{ categories[1]._id }}", "name": "Products Update A" } |
      | {{ categories[4]._id }} | Products Update D | { "_id": "{{ categories[1]._id }}", "name": "Products Update A" } |
    When I make a GET request to the API endpoint "/admin/categories" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[4] | 4     | 0    | 20    |
    And the response path "list" from the "category" request partially contains:
      | _id                     | name              | products |
      | {{ categories[1]._id }} | Products Update A | 0        |
      | {{ categories[2]._id }} | Products Update B | 1        |
      | {{ categories[3]._id }} | Products Update C | 1        |
      | {{ categories[4]._id }} | Products Update D | 1        |

  Scenario: Removal of products from a category updates the categories
    Given I am logged in with the "product-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/products/{{ products[1]._id }}" as "product" using:
      | op      | path       | value                       |
      | replace | categories | ["{{ categories[3]._id }}"] |
    Then there should be a 200 response from the "product" request that contains:
      | _id       | slug                 | code                | displayName          | description         | promotionalImage                                                                            | previousPrice | currentPrice | categories | history  | status | created   | updated   |
      | OBJECT_ID | product-update-patch | PRODUCT-UPDATE-0001 | Product Update PATCH | Updated Description | https://images.venzra-test.com/{{ subscriptions[1]._id }}/promotion/{{ images[1]._id }}.jpg | 8             | 5            | ARRAY[1]   | ARRAY[6] | ACTIVE | DATE_TIME | DATE_TIME |
    When I make a GET request to the API endpoint "/admin/categories" as "category"
    Then there should be a 200 response from the "category" request that contains:
      | list     | total | skip | limit |
      | ARRAY[4] | 4     | 0    | 20    |
    And the response path "list" from the "category" request partially contains:
      | _id                     | name              | products |
      | {{ categories[1]._id }} | Products Update A | 0        |
      | {{ categories[2]._id }} | Products Update B | 0        |
      | {{ categories[3]._id }} | Products Update C | 1        |
      | {{ categories[4]._id }} | Products Update D | 0        |
