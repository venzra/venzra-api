@Store @Cart @CartShipping
Feature: Assigning shipping onptions to a cart

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName         | status |
      | Cart Shipping One | ACTIVE |
      | Cart Shipping Two | ACTIVE |
    And there are the following "shipping" records in the database
      | subscription               | displayName | cartMinimum | cartMaximum | currentPrice | shipmentTime |
      | {{ subscriptions[1]._id }} | Shipping A  | 0           | 0           | 100          | 24           |
      | {{ subscriptions[1]._id }} | Shipping B  | 0           | 0           | 200          | 48           |
      | {{ subscriptions[1]._id }} | Example A   | 0           | 0           | 300          | 72           |
      | {{ subscriptions[2]._id }} | Example B   | 0           | 0           | 400          | 96           |
    And there are the following "images" records in the database
      | subscription               | name                 | usage     | size |
      | {{ subscriptions[1]._id }} | CartShipping Image A | promotion | 1024 |
      | {{ subscriptions[2]._id }} | CartShipping Image B | promotion | 1024 |
    And there are the following "products" records in the database
      | subscription               | code            | slug             | displayName      | description           | promotionalImage    | currentPrice | status   |
      | {{ subscriptions[1]._id }} | SHIPPING-01-001 | cart-shipping-a  | Cart Shipping A  | Automated description | {{ images[1]._id }} | 9            | ACTIVE   |
      | {{ subscriptions[1]._id }} | SHIPPING-01-002 | cart-shipping-aa | Cart Shipping AA | Automated description | {{ images[1]._id }} | 99           | ACTIVE   |
      | {{ subscriptions[1]._id }} | SHIPPING-01-003 | cart-shipping-b  | Cart Shipping B  | Automated description | {{ images[1]._id }} | 999          | INACTIVE |
      | {{ subscriptions[2]._id }} | SHIPPING-02-001 | cart-shipping-a  | Cart Shipping A  | Automated description | {{ images[2]._id }} | 999          | ACTIVE   |
      | {{ subscriptions[2]._id }} | SHIPPING-02-002 | cart-shipping-b  | Cart Shipping B  | Automated description | {{ images[2]._id }} | 999          | INACTIVE |
    And there are the following "carts" records in the database
      | subscription               | ip        | items                                    | shipping                                                                    |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | [{ "product": "{{ products[1]._id }}" }] |                                                                             |
      | {{ subscriptions[1]._id }} | 127.0.0.1 | []                                       | { "reference": "{{ shipping[3]._id }}", "name": "Example A", "price": 300 } |
      | {{ subscriptions[2]._id }} | 127.0.0.1 | [{ "product": "{{ products[4]._id }}" }] | { "reference": "{{ shipping[4]._id }}", "name": "Example B", "price": 400 } |

  Scenario: Sending a request to replace shipping to a cart without shipping adds the requested entry data
    Given the request origin headers are set to "cart-shipping-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[1]._id }}"
    When I make a PATCH request to the API endpoint "/store/cart" as "cart" using:
      | op      | path     | value                 |
      | replace | shipping | {{ shipping[1]._id }} |
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | shipping                                                                     | value |
      | OBJECT_ID | ARRAY[1] | { "reference": "{{ shipping[1]._id }}", "name": "Shipping A", "price": 100 } | 9     |

  Scenario: Sending a request to replace shipping on a cart with shipping replaces the existing entry
    Given the request origin headers are set to "cart-shipping-one.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[2]._id }}"
    When I make a PATCH request to the API endpoint "/store/cart" as "cart" using:
      | op      | path     | value                 |
      | replace | shipping | {{ shipping[2]._id }} |
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | shipping                                                                     | value |
      | OBJECT_ID | ARRAY[0] | { "reference": "{{ shipping[2]._id }}", "name": "Shipping B", "price": 200 } | 0     |

  Scenario: Attempting to assign shipping to a cart that does not belong to the subscription fails to make any change
    Given the request origin headers are set to "cart-shipping-two.venzra-test.io"
    And I set the "vid" cookie to the value "{{ carts[3]._id }}"
    When I make a PATCH request to the API endpoint "/store/cart" as "cart" using:
      | op      | path     | value                 |
      | replace | shipping | {{ shipping[1]._id }} |
    Then there should be a 200 response from the "cart" request that contains:
      | _id       | items    | shipping                                                                    | value |
      | OBJECT_ID | ARRAY[1] | { "reference": "{{ shipping[4]._id }}", "name": "Example B", "price": 400 } | 999   |
