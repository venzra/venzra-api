@Admin @Products @ProductsCreate
Feature: Creation of a new product entry

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                  | status |
      | Admin Products Create One  | ACTIVE |
      | Admin  Products Create Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | products-create-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | products-create-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                   | usage     | size |
      | {{ subscriptions[1]._id }} | ProductsCreate Image A | promotion | 1024 |
      | {{ subscriptions[1]._id }} | ProductsCreate Image B | promotion | 4096 |
      | {{ subscriptions[2]._id }} | ProductsCreate Image C | promotion | 2048 |
    And there are the following "products" records in the database
      | subscription               | code       | displayName      | description           | promotionalImage    | currentPrice | status |
      | {{ subscriptions[1]._id }} | CREATE-001 | Product Create A | Automated Description | {{ images[2]._id }} | 999          | ACTIVE |

  Scenario: An empty request to create a product fails validation
    Given I am logged in with the "products-create-one@venzra-test.io" admin account
    When I make an empty POST request to the API endpoint "/admin/products" as "product"
    Then there should be a 400 error from the "product" request that contains:
      | message           | detail                                                                                                                  |
      | Validation failed | ["code required", "displayName required", "description required", "promotionalImage required", "currentPrice required"] |

  Scenario: If the product already exists then the request should be rejected (based on product code)
    Given I am logged in with the "products-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/products" as "product" using:
      | code                   | displayName        | description           | promotionalImage    | currentPrice |
      | {{ products[1].code }} | Product Create AAA | Automated Description | {{ images[2]._id }} | 99           |
    Then there should be a 400 response from the "product" request that contains:
      | message               | detail |
      | Record already exists | []     |

  Scenario: If the product already exists then the request should be rejected (based on product name)
    Given I am logged in with the "products-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/products" as "product" using:
      | code       | displayName                   | description           | promotionalImage    | currentPrice |
      | CREATE-999 | {{ products[1].displayName }} | Automated Description | {{ images[2]._id }} | 99           |
    Then there should be a 400 response from the "product" request that contains:
      | message               | detail |
      | Record already exists | []     |

  Scenario: A valid request to create a new product record is successful (also strips any decimal places on price)
    Given I am logged in with the "products-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/products" as "product" using:
      | code       | displayName      | description           | promotionalImage    | currentPrice |
      | CREATE-002 | Product Create B | Automated Description | {{ images[1]._id }} | 99.99        |
    Then there should be a 200 response from the "product" request that contains:
      | _id       | slug             | code       | displayName      | description           | promotionalImage                                                                            | previousPrice | currentPrice | categories | history  | status   | created   | updated   |
      | OBJECT_ID | product-create-b | CREATE-002 | Product Create B | Automated Description | https://images.venzra-test.com/{{ subscriptions[1]._id }}/promotion/{{ images[1]._id }}.jpg | 0             | 99           | ARRAY[0]   | ARRAY[0] | INACTIVE | DATE_TIME | DATE_TIME |

  Scenario: An account linked to another subscription can use the same product code and name already used by a different subscription, also allows for setting of status
    Given I am logged in with the "products-create-two@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/products" as "product" using:
      | code                   | displayName                   | description           | promotionalImage    | previousPrice | currentPrice | status |
      | {{ products[1].code }} | {{ products[1].displayName }} | Automated Description | {{ images[3]._id }} | 104.99        | 99.49        | ACTIVE |
    Then there should be a 200 response from the "product" request that contains:
      | _id       | slug             | code       | displayName      | description           | promotionalImage                                                                            | previousPrice | currentPrice | categories | history  | status | created   | updated   |
      | OBJECT_ID | product-create-a | CREATE-001 | Product Create A | Automated Description | https://images.venzra-test.com/{{ subscriptions[2]._id }}/promotion/{{ images[3]._id }}.jpg | 104           | 99           | ARRAY[0]   | ARRAY[0] | ACTIVE | DATE_TIME | DATE_TIME |
