@Store @Products @ProductsSearch
Feature: Creation of a new product entry

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                   | status |
      | Store Products Search One   | ACTIVE |
      | Store Products Search Two   | ACTIVE |
      | Store Products Search Three | ACTIVE |
    And there are the following "images" records in the database
      | subscription               | name                   | usage     | size |
      | {{ subscriptions[1]._id }} | ProductsSearch Image A | promotion | 4096 |
      | {{ subscriptions[2]._id }} | ProductsSearch Image B | promotion | 4096 |
    And there are the following "products" records in the database
      | subscription               | code          | slug               | displayName        | description                 | promotionalImage    | previousPrice | currentPrice | status   |
      | {{ subscriptions[1]._id }} | SEARCH-01-001 | product-search-a   | Product Search A   | Automated description A     | {{ images[1]._id }} | 0             | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-002 | product-search-aa  | Product Search AA  | Automated description A     | {{ images[1]._id }} | 0             | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-003 | product-search-aaa | Product Search AAA | Automated description AA    | {{ images[1]._id }} | 5000          | 999          | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-004 | product-search-b   | Product Search B   | Automated description AA AA | {{ images[1]._id }} | 9             | 6            | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-005 | product-search-bb  | Product Search BB  | Automated description AAA   | {{ images[1]._id }} | 99            | 66           | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-006 | product-search-c   | Product Search C   | Automated description AAA   | {{ images[1]._id }} | 0             | 0            | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-007 | product-search-d   | Product Search D   | Automated description B     | {{ images[1]._id }} | 500           | 1000         | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-008 | product-search-e   | Product Search E   | Automated description B     | {{ images[1]._id }} | 0             | 2000         | ACTIVE   |
      | {{ subscriptions[1]._id }} | SEARCH-01-009 | product-search-f   | Product Search F   | Automated description BB    | {{ images[1]._id }} | 0             | 3000         | INACTIVE |
      | {{ subscriptions[1]._id }} | SEARCH-01-010 | product-search-g   | Product Search G   | Automated description BB BB | {{ images[1]._id }} | 10            | 5            | INACTIVE |
      | {{ subscriptions[1]._id }} | SEARCH-01-011 | product-search-gg  | Product Search GG  | Automated description BBB   | {{ images[1]._id }} | 100           | 50           | INACTIVE |
      | {{ subscriptions[1]._id }} | SEARCH-01-012 | product-search-ggg | Product Search GGG | Automated description BBB   | {{ images[1]._id }} | 1000          | 500          | ACTIVE   |
      | {{ subscriptions[2]._id }} | SEARCH-02-001 | product-search-a   | Product Search A   | Automated description A     | {{ images[2]._id }} | 0             | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | SEARCH-02-002 | product-search-b   | Product Search B   | Automated description A     | {{ images[2]._id }} | 0             | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | SEARCH-02-003 | product-search-c   | Product Search C   | Automated description AA    | {{ images[2]._id }} | 0             | 999          | INACTIVE |
    And there are the following "categories" records in the database in series
      | subscription               | name                 | description           | featureImage        | primary |
      | {{ subscriptions[1]._id }} | Category Summary A   | Automated description | {{ images[1]._id }} | true    |
      | {{ subscriptions[1]._id }} | Category Summary AA  | Automated description |                     | true    |
      | {{ subscriptions[1]._id }} | Category Summary AAA | Automated description | {{ images[2]._id }} | false   |
    And the following "categories" records are updated in the database
      | _id                     | parent                  | children                                               | products                                                                    |
      | {{ categories[1]._id }} | null                    | ["{{ categories[2]._id }}", "{{ categories[3]._id }}"] | null                                                                        |
      | {{ categories[2]._id }} | {{ categories[1]._id }} | []                                                     | ["{{ products[2]._id }}", "{{ products[3]._id }}"]                          |
      | {{ categories[3]._id }} | {{ categories[1]._id }} | []                                                     | ["{{ products[2]._id }}", "{{ products[4]._id }}", "{{ products[5]._id }}"] |
    And the following "products" records are updated in the database
      | _id                   | categories                                             |
      | {{ products[2]._id }} | ["{{ categories[2]._id }}", "{{ categories[3]._id }}"] |
      | {{ products[3]._id }} | ["{{ categories[2]._id }}"]                            |
      | {{ products[4]._id }} | ["{{ categories[3]._id }}"]                            |
      | {{ products[5]._id }} | ["{{ categories[3]._id }}"]                            |

  Scenario: Requesting a list of products should return only records for that subscription (subscription one)
    Given the request origin headers are set to "store-products-search-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | list     | total | skip | limit |
      | ARRAY[9] | 9     | 0    | 24    |
    And the "product" request that has a "list" field and row 1 contains:
      | _id       | slug             | code          | displayName      | promotionalImage                                                                              | previousPrice | currentPrice |
      | OBJECT_ID | product-search-a | SEARCH-01-001 | Product Search A | https://images.venzra-test.com/{{ images[1].subscription }}/promotion/{{ images[1]._id }}.jpg | 0             | 9            |

  Scenario: Requesting a list of products should return only records for that subscription (subscription two)
    Given the request origin headers are set to "store-products-search-two.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | list     | total | skip | limit |
      | ARRAY[2] | 2     | 0    | 24    |
    And the "product" request that has a "list" field and row 1 contains:
      | _id       | slug             | code          | displayName      | promotionalImage                                                                              | previousPrice | currentPrice |
      | OBJECT_ID | product-search-a | SEARCH-02-001 | Product Search A | https://images.venzra-test.com/{{ images[2].subscription }}/promotion/{{ images[2]._id }}.jpg | 0             | 999          |

  Scenario: Requesting a list of products should return no results when there are no products (subscription three)
    Given the request origin headers are set to "store-products-search-three.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | list     | total | skip | limit |
      | ARRAY[0] | 0     | 0    | 24    |

  Scenario: Requesting a list of products adheres to pagination values for skip and limit
    Given the request origin headers are set to "store-products-search-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products?skip=2&limit=4" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | list     | total | skip | limit |
      | ARRAY[4] | 9     | 2    | 4     |
    And the "product" request that has a "list" field and row 1 contains:
      | _id       | slug               | code          | displayName        | promotionalImage                                                                              | previousPrice | currentPrice |
      | OBJECT_ID | product-search-aaa | SEARCH-01-003 | Product Search AAA | https://images.venzra-test.com/{{ images[1].subscription }}/promotion/{{ images[1]._id }}.jpg | 5000          | 999          |

  Scenario: Listing of products supports searching by name
    Given the request origin headers are set to "store-products-search-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products?search=aa" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | list     | total | skip | limit |
      | ARRAY[3] | 3     | 0    | 24    |
    And the "product" request that has a "list" field and row 1 contains:
      | _id       | slug              | code          | displayName       | promotionalImage                                                                              | previousPrice | currentPrice |
      | OBJECT_ID | product-search-aa | SEARCH-01-002 | Product Search AA | https://images.venzra-test.com/{{ images[1].subscription }}/promotion/{{ images[1]._id }}.jpg | 0             | 99           |

  Scenario: Listing of products supports searching by category
    Given the request origin headers are set to "store-products-search-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products?category=category-summary-aa" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | list     | total | skip | limit |
      | ARRAY[2] | 2     | 0    | 24    |
    And the "product" request that has a "list" field and row 1 contains:
      | _id       | slug              | code          | displayName       | promotionalImage                                                                              | previousPrice | currentPrice |
      | OBJECT_ID | product-search-aa | SEARCH-01-002 | Product Search AA | https://images.venzra-test.com/{{ images[1].subscription }}/promotion/{{ images[1]._id }}.jpg | 0             | 99           |

  Scenario: Listing of products supports searching by parent category
    Given the request origin headers are set to "store-products-search-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products?category=category-summary-a" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | list     | total | skip | limit |
      | ARRAY[4] | 4     | 0    | 24    |
    And the "product" request that has a "list" field and row 1 contains:
      | _id       | slug              | code          | displayName       | promotionalImage                                                                              | previousPrice | currentPrice |
      | OBJECT_ID | product-search-aa | SEARCH-01-002 | Product Search AA | https://images.venzra-test.com/{{ images[1].subscription }}/promotion/{{ images[1]._id }}.jpg | 0             | 99           |

  Scenario: Listing of products returns no results for a non-existent category
    Given the request origin headers are set to "store-products-search-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products?category=category-fake" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | list     | total | skip | limit |
      | ARRAY[0] | 0     | 0    | 24    |
