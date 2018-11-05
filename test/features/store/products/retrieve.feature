@Store @Products @ProductsRetrieve
Feature: Creation of a new product entry

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName             | status |
      | Products Retrieve One | ACTIVE |
      | Products Retrieve Two | ACTIVE |
    And there are the following "images" records in the database
      | subscription               | name                     | usage     | size |
      | {{ subscriptions[1]._id }} | ProductsRetrieve Image A | promotion | 4096 |
      | {{ subscriptions[2]._id }} | ProductsRetrieve Image B | promotion | 4096 |
    And there are the following "products" records in the database
      | subscription               | code            | slug                | displayName         | description           | promotionalImage    | previousPrice | currentPrice | status   |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-001 | product-retrieve-a  | Product Retrieve A  | Automated description | {{ images[1]._id }} | 0             | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-002 | product-retrieve-aa | Product Retrieve AA | Automated description | {{ images[1]._id }} | 50            | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-003 | product-retrieve-b  | Product Retrieve B  | Automated description | {{ images[1]._id }} | 1000          | 999          | INACTIVE |
      | {{ subscriptions[2]._id }} | RETRIEVE-02-001 | product-retrieve-a  | Product Retrieve A  | Automated description | {{ images[2]._id }} | 2000          | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | RETRIEVE-02-002 | product-retrieve-b  | Product Retrieve B  | Automated description | {{ images[2]._id }} | 0             | 999          | INACTIVE |

  Scenario: Attempting to retrieve an INACTIVE product gives no result
    Given the request origin headers are set to "products-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products/{{ products[3].slug }}" as "product"
    Then the status returned from the "product" request should be a 404 error

  Scenario: Successful retrieval of a record will give a result
    Given the request origin headers are set to "products-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products/{{ products[2].slug }}" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | _id       | code            | slug                | displayName         | description           | promotionalImage                                                                              | previousPrice | currentPrice |
      | OBJECT_ID | RETRIEVE-01-002 | product-retrieve-aa | Product Retrieve AA | Automated description | https://images.venzra-test.com/{{ images[1].subscription }}/promotion/{{ images[1]._id }}.jpg | 50            | 99           |

  Scenario: It is not possible to retrieve a product that belongs to a different subscription
    Given the request origin headers are set to "products-retrieve-two.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products/{{ products[2].slug }}" as "product"
    Then the status returned from the "product" request should be a 404 error

  Scenario: If the product slug exists on multiple subscriptions then it returns the correct one
    Given the request origin headers are set to "products-retrieve-two.venzra-test.io"
    When I make a GET request to the API endpoint "/store/products/{{ products[1].slug }}" as "product"
    Then there should be a 200 response from the "product" request that contains:
      | _id       | code            | slug               | displayName        | description           | promotionalImage                                                                              | previousPrice | currentPrice |
      | OBJECT_ID | RETRIEVE-02-001 | product-retrieve-a | Product Retrieve A | Automated description | https://images.venzra-test.com/{{ images[2].subscription }}/promotion/{{ images[2]._id }}.jpg | 2000          | 999          |
