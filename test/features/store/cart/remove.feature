@Store @Cart @CartRemove
Feature: Removing products from a cart

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName       | status |
      | Cart Remove One | ACTIVE |
      | Cart Remove Two | ACTIVE |
    And there are the following "shipping" records in the database
      | subscription               | displayName | cartMinimum | cartMaximum | currentPrice | shipmentTime |
      | {{ subscriptions[1]._id }} | Example A   | 0           | 0           | 100          | 24           |
      | {{ subscriptions[1]._id }} | Example B   | 0           | 0           | 200          | 48           |
      | {{ subscriptions[1]._id }} | Example C   | 0           | 0           | 300          | 72           |
      | {{ subscriptions[2]._id }} | Example D   | 0           | 0           | 400          | 96           |
    And there are the following "images" records in the database
      | subscription               | name               | usage     | size |
      | {{ subscriptions[1]._id }} | CartRemove Image A | promotion | 1024 |
      | {{ subscriptions[2]._id }} | CartRemove Image B | promotion | 1024 |
    And there are the following "products" records in the database
      | subscription               | code          | slug           | displayName    | description           | promotionalImage    | currentPrice | status   |
      | {{ subscriptions[1]._id }} | REMOVE-01-001 | cart-remove-a  | Cart Remove A  | Automated description | {{ images[1]._id }} | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | REMOVE-01-002 | cart-remove-aa | Cart Remove AA | Automated description | {{ images[1]._id }} | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | REMOVE-01-003 | cart-remove-b  | Cart Remove B  | Automated description | {{ images[1]._id }} | 999          | INACTIVE |
      | {{ subscriptions[2]._id }} | REMOVE-02-001 | cart-remove-a  | Cart Remove A  | Automated description | {{ images[2]._id }} | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | REMOVE-02-002 | cart-remove-b  | Cart Remove B  | Automated description | {{ images[2]._id }} | 999          | INACTIVE |
    And there are the following "carts" records in the database
      | subscription               | ip        | items                                                                                                          | shipping                                                                    |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | []                                                                                                             | { "reference": "{{ shipping[1]._id }}", "name": "Example A", "price": 100 } |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | [{ "product": "{{ products[1]._id }}" }, { "product": "{{ products[3]._id }}" }]                               | { "reference": "{{ shipping[2]._id }}", "name": "Example B", "price": 200 } |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | [{ "product": "{{ products[1]._id }}", "quantity": 3 }, { "product": "{{ products[2]._id }}", "quantity": 2 }] | { "reference": "{{ shipping[3]._id }}", "name": "Example C", "price": 300 } |
      | {{ subscriptions[2]._id }} | 127.0.0.1 | [{ "product": "{{ products[4]._id }}" }, { "product": "{{ products[5]._id }}" }]                               | { "reference": "{{ shipping[4]._id }}", "name": "Example D", "price": 400 } |

  Scenario: Removing a product that is not in the cart is ignored
    Given the request origin headers are set to "cart-remove-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[1]._id }}"
    When I make a PATCH request to the API endpoint "/store/cart" as "cart" using:
      | op     | path    | value                 |
      | remove | product | {{ products[1]._id }} |
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | shipping                                                                    | value |
      | OBJECT_ID | ARRAY[0] | { "reference": "{{ shipping[1]._id }}", "name": "Example A", "price": 100 } | 0     |

  Scenario: Removing a product that is inactive does not matter
    Given the request origin headers are set to "cart-remove-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[2]._id }}"
    When I make a PATCH request to the API endpoint "/store/cart" as "cart" using:
      | op     | path    | value                 |
      | remove | product | {{ products[3]._id }} |
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | value |
      | OBJECT_ID | ARRAY[1] | 9     |

  Scenario: Updating a cart to remove a product will take it out of the cart
    Given the request origin headers are set to "cart-remove-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[2]._id }}"
    When I make a PATCH request to the API endpoint "/store/cart" as "cart" using:
      | op     | path    | value                 |
      | remove | product | {{ products[1]._id }} |
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | value |
      | OBJECT_ID | ARRAY[0] | 0     |

  Scenario: Removing a product that has more than 1 quantity from the cart just decrements the quantity by 1
    Given the request origin headers are set to "cart-remove-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[3]._id }}"
    When I make a PATCH request to the API endpoint "/store/cart" as "cart" using:
      | op     | path    | value                 |
      | remove | product | {{ products[1]._id }} |
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | value |
      | OBJECT_ID | ARRAY[2] | 216   |
    And the "cart" request that has an "items" field and row 1 contains:
      | _id       | product                                               | quantity |
      | OBJECT_ID | OBJECT[_id,displayName,promotionalImage,currentPrice] | 2        |
    And the "cart" request that has an "items" field and row 2 contains:
      | _id       | product                                               | quantity |
      | OBJECT_ID | OBJECT[_id,displayName,promotionalImage,currentPrice] | 2        |

  Scenario: It is possible to run multiple operations in a single call to remove several quantity or when quantity would hit 0 remove the item
    Given the request origin headers are set to "cart-remove-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[3]._id }}"
    When I make a PATCH request to the API endpoint "/store/cart" as "cart" using:
      | op     | path    | value                 |
      | remove | product | {{ products[1]._id }} |
      | remove | product | {{ products[2]._id }} |
      | remove | product | {{ products[2]._id }} |
      | remove | product | {{ products[2]._id }} |
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | value |
      | OBJECT_ID | ARRAY[1] | 9     |
    And the "cart" request that has an "items" field and row 1 contains:
      | _id       | product                                               | quantity |
      | OBJECT_ID | OBJECT[_id,displayName,promotionalImage,currentPrice] | 1        |
