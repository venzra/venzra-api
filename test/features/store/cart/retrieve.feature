@Store @Cart @CartRetrieve
Feature: Access cart data available for a customer

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName         | status |
      | Cart Retrieve One | ACTIVE |
      | Cart Retrieve Two | ACTIVE |
    And there are the following "images" records in the database
      | subscription               | name                 | usage     | size |
      | {{ subscriptions[1]._id }} | CartRetrieve Image A | promotion | 1024 |
      | {{ subscriptions[2]._id }} | CartRetrieve Image B | promotion | 1024 |
    And there are the following "products" records in the database
      | subscription               | code            | slug             | displayName      | description           | promotionalImage    | currentPrice | status   |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-001 | cart-retrieve-a  | Cart Retrieve A  | Automated description | {{ images[1]._id }} | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-002 | cart-retrieve-aa | Cart Retrieve AA | Automated description | {{ images[1]._id }} | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | RETRIEVE-01-003 | cart-retrieve-b  | Cart Retrieve B  | Automated description | {{ images[1]._id }} | 999          | INACTIVE |
      | {{ subscriptions[2]._id }} | RETRIEVE-02-001 | cart-retrieve-a  | Cart Retrieve A  | Automated description | {{ images[1]._id }} | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | RETRIEVE-02-002 | cart-retrieve-b  | Cart Retrieve B  | Automated description | {{ images[1]._id }} | 999          | INACTIVE |
    And there are the following "carts" records in the database
      | subscription               | ip        | items                                                                                                                                   |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | []                                                                                                                                      |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | [{ "product": "{{ products[1]._id }}" }]                                                                                                |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | [{ "product": "{{ products[1]._id }}", "quantity": 2 }, { "product": "{{ products[2]._id }}" }, { "product": "{{ products[3]._id }}" }] |
      | {{ subscriptions[2]._id }} | 127.0.0.1 | [{ "product": "{{ products[4]._id }}" }, { "product": "{{ products[5]._id }}" }]                                                        |

  Scenario: Attempting to a cart which belongs to another subscription will give a new empty cart in return
    Given the request origin headers are set to "cart-retrieve-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[4]._id }}"
    When I make a GET request to the API endpoint "/store/cart" as "cart"
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | value |
      | OBJECT_ID | ARRAY[0] | 0     |

  Scenario: Successful retrieval of an empty cart will give a result
    Given the request origin headers are set to "cart-retrieve-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[1]._id }}"
    When I make a GET request to the API endpoint "/store/cart" as "cart"
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | value |
      | OBJECT_ID | ARRAY[0] | 0     |

  Scenario: Successful retrieval of a cart with a single item will give a result
    Given the request origin headers are set to "cart-retrieve-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[2]._id }}"
    When I make a GET request to the API endpoint "/store/cart" as "cart"
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | value |
      | OBJECT_ID | ARRAY[1] | 9     |
    And the "cart" request that has an "items" field and row 1 contains:
      | _id       | product                                               | quantity |
      | OBJECT_ID | OBJECT[_id,displayName,promotionalImage,currentPrice] | 1        |
    And the "cart" request that has an "items" field and row 1 contains an object called "product" with:
      | _id       | displayName     | promotionalImage                                                                              | currentPrice |
      | OBJECT_ID | Cart Retrieve A | https://images.venzra-test.com/{{ images[1].subscription }}/promotion/{{ images[1]._id }}.jpg | 9            |

  Scenario: Successful retrieval of a complex cart will give a result with quantity counts and any inactive products removed
    Given the request origin headers are set to "cart-retrieve-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[3]._id }}"
    When I make a GET request to the API endpoint "/store/cart" as "cart"
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | value |
      | OBJECT_ID | ARRAY[2] | 117   |
    And the "cart" request that has an "items" field and row 1 contains:
      | _id       | product                                               | quantity |
      | OBJECT_ID | OBJECT[_id,displayName,promotionalImage,currentPrice] | 2        |
    And the "cart" request that has an "items" field and row 2 contains:
      | _id       | product                                               | quantity |
      | OBJECT_ID | OBJECT[_id,displayName,promotionalImage,currentPrice] | 1        |
