@Store @Customer @CustomerAddresses
Feature: Add or remove an address for a customer

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName              | status |
      | Customer Addresses One | ACTIVE |
      | Customer Addresses Two | ACTIVE |
    And there are the following "customers" records in the database
      | identity                              | password | addresses | status | subscription               |
      | customer-addresses-one@venzra-test.io | PASSWORD | []        | ACTIVE | {{ subscriptions[1]._id }} |

  Scenario: Adding an address to a customer record (missing fields)
    Given the request origin headers are set to "customer-addresses-one.venzra-test.io"
    And I am logged in with the "customer-addresses-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/customer/addresses" as "customer" using:
      | building |
      | one      |
    Then there should be a 400 error from the "customer" request that contains:
      | message           | detail                                                                                                  |
      | Validation failed | ["addressee required", "street required", "county required", "country required", "postalCode required"] |

  Scenario: Adding an address to a customer record all fields present
    Given the request origin headers are set to "customer-addresses-one.venzra-test.io"
    And I am logged in with the "customer-addresses-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/customer/addresses" as "customer" using:
      | addressee    | building | street         | city         | county         | postalCode | country |
      | Mr Automated | One      | Example street | Example city | Example county | ex4 mp1    | GB      |
    Then there should be a 200 response from the "customer" request that contains:
      | _id       | identity                              | addresses | primaryAddress                  | status |
      | OBJECT_ID | customer-addresses-one@venzra-test.io | ARRAY[1]  | {{ customer.addresses[1]._id }} | ACTIVE |
    And the response from the "customer" request has a "addresses" that contains rows:
      | _id       | addressee    | building | street         | city         | county         | postalCode | country |
      | OBJECT_ID | Mr Automated | One      | Example street | Example city | Example county | EX4MP1     | GB      |

  Scenario: Adding a second address to a customer record does not change the primary address
    Given the request origin headers are set to "customer-addresses-one.venzra-test.io"
    And I am logged in with the "customer-addresses-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/customer/addresses" as "customer" using:
      | addressee        | street         | county         | postalCode | country |
      | Mr Automated Two | Example street | Example county | ex4 mp1    | GB      |
    Then there should be a 200 response from the "customer" request that contains:
      | _id       | identity                              | addresses | primaryAddress                  | status |
      | OBJECT_ID | customer-addresses-one@venzra-test.io | ARRAY[2]  | {{ customer.addresses[1]._id }} | ACTIVE |
    And there should be a 200 response from the "customer" request that has an "addresses" field and row 1 contains:
      | _id       | addressee    | building | street         | city         | county         | postalCode | country |
      | OBJECT_ID | Mr Automated | One      | Example street | Example city | Example county | EX4MP1     | GB      |
    And there should be a 200 response from the "customer" request that has an "addresses" field and row 2 contains:
      | _id       | addressee        | street         | county         | postalCode | country |
      | OBJECT_ID | Mr Automated Two | Example street | Example county | EX4MP1     | GB      |

  Scenario: Adding a third address to a customer record will change the primary address when the flag is set
    Given the request origin headers are set to "customer-addresses-one.venzra-test.io"
    And I am logged in with the "customer-addresses-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/customer/addresses" as "customer" using:
      | addressee          | street         | county         | postalCode | country | makeDefault |
      | Mr Automated Three | Example street | Example county | ex4 mp1    | GB      | true        |
    Then there should be a 200 response from the "customer" request that contains:
      | _id       | identity                              | addresses | primaryAddress                  | status |
      | OBJECT_ID | customer-addresses-one@venzra-test.io | ARRAY[3]  | {{ customer.addresses[3]._id }} | ACTIVE |
    And there should be a 200 response from the "customer" request that has an "addresses" field and row 1 contains:
      | _id       | addressee    | building | street         | city         | county         | postalCode | country |
      | OBJECT_ID | Mr Automated | One      | Example street | Example city | Example county | EX4MP1     | GB      |
    And there should be a 200 response from the "customer" request that has an "addresses" field and row 2 contains:
      | _id       | addressee        | street         | county         | postalCode | country |
      | OBJECT_ID | Mr Automated Two | Example street | Example county | EX4MP1     | GB      |
    And there should be a 200 response from the "customer" request that has an "addresses" field and row 3 contains:
      | _id       | addressee          | street         | county         | postalCode | country |
      | OBJECT_ID | Mr Automated Three | Example street | Example county | EX4MP1     | GB      |

  Scenario: Removing the default address assigns the first record to be the default
    Given the request origin headers are set to "customer-addresses-one.venzra-test.io"
    And I am logged in with the "customer-addresses-one@venzra-test.io" account
    When I make a DELETE request to the API endpoint "/store/customer/addresses/{{ customer.addresses[3]._id }}" as "check"
    Then the status returned from the "check" request should be 202
    When I make a GET request to the API endpoint "/store/customer" as "customer"
    Then there should be a 200 response from the "customer" request that contains:
      | _id       | identity                              | addresses | primaryAddress                  | status |
      | OBJECT_ID | customer-addresses-one@venzra-test.io | ARRAY[2]  | {{ customer.addresses[1]._id }} | ACTIVE |
    And there should be a 200 response from the "customer" request that has an "addresses" field and row 1 contains:
      | _id       | addressee    | building | street         | city         | county         | postalCode | country |
      | OBJECT_ID | Mr Automated | One      | Example street | Example city | Example county | EX4MP1     | GB      |
    And there should be a 200 response from the "customer" request that has an "addresses" field and row 2 contains:
      | _id       | addressee        | street         | county         | postalCode | country |
      | OBJECT_ID | Mr Automated Two | Example street | Example county | EX4MP1     | GB      |

  Scenario: Removing a normal (non-default) address is acceptable
    Given the request origin headers are set to "customer-addresses-one.venzra-test.io"
    And I am logged in with the "customer-addresses-one@venzra-test.io" account
    When I make a DELETE request to the API endpoint "/store/customer/addresses/{{ customer.addresses[2]._id }}" as "check"
    Then the status returned from the "check" request should be 202
    When I make a GET request to the API endpoint "/store/customer" as "customer"
    Then there should be a 200 response from the "customer" request that contains:
      | _id       | identity                              | addresses | primaryAddress                  | status |
      | OBJECT_ID | customer-addresses-one@venzra-test.io | ARRAY[1]  | {{ customer.addresses[1]._id }} | ACTIVE |
    And there should be a 200 response from the "customer" request that has an "addresses" field and row 1 contains:
      | _id       | addressee    | building | street         | city         | county         | postalCode | country |
      | OBJECT_ID | Mr Automated | One      | Example street | Example city | Example county | EX4MP1     | GB      |

  Scenario: Removing an address to a customer record is ignored (invalid reference)
    Given the request origin headers are set to "customer-addresses-one.venzra-test.io"
    And I am logged in with the "customer-addresses-one@venzra-test.io" account
    When I make a DELETE request to the API endpoint "/store/customer/addresses/{{ customers[1]._id }}" as "check"
    Then the status returned from the "check" request should be 202
    When I make a GET request to the API endpoint "/store/customer" as "customer"
    Then there should be a 200 response from the "customer" request that contains:
      | _id       | identity                              | addresses | primaryAddress                  | status |
      | OBJECT_ID | customer-addresses-one@venzra-test.io | ARRAY[1]  | {{ customer.addresses[1]._id }} | ACTIVE |

  Scenario: Removing the last address of a customer record
    Given the request origin headers are set to "customer-addresses-one.venzra-test.io"
    And I am logged in with the "customer-addresses-one@venzra-test.io" account
    When I make a DELETE request to the API endpoint "/store/customer/addresses/{{ customer.addresses[1]._id }}" as "check"
    Then the status returned from the "check" request should be 202
    When I make a GET request to the API endpoint "/store/customer" as "customer"
    Then there should be a 200 response from the "customer" request that contains:
      | _id       | identity                              | addresses | status |
      | OBJECT_ID | customer-addresses-one@venzra-test.io | ARRAY[0]  | ACTIVE |
