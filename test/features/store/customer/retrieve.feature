@Store @Customer @CustomerRetrieve
Feature: Retrieve currently logged in customer information

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName             | status |
      | Customer Retrieve One | ACTIVE |
      | Customer Retrieve Two | ACTIVE |
    And there are the following "customers" records in the database
      | identity                             | password | addresses                                                                                                          | status | subscription               |
      | customer-retrieve-one@venzra-test.io | PASSWORD | []                                                                                                                 | ACTIVE | {{ subscriptions[1]._id }} |
      | customer-retrieve-two@venzra-test.io | PASSWORD | [{ "addressee": "Mr Address", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" }] | ACTIVE | {{ subscriptions[1]._id }} |

  Scenario: When there is no logged in user there should be no response
    Given the request origin headers are set to "customer-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/customer" as "customer"
    Then the status returned from the "customer" request should be a 401 error

  Scenario: After logging in using another subdomain will result in no record
    Given the request origin headers are set to "customer-retrieve-one.venzra-test.io"
    And I am logged in with the "customer-retrieve-one@venzra-test.io" account
    And the request origin headers are set to "customer-retrieve-two.venzra-test.io"
    When I make a GET request to the API endpoint "/store/customer" as "customer"
    Then the status returned from the "customer" request should be a 401 error

  Scenario: Retrieve customer profile information (without addresses)
    Given the request origin headers are set to "customer-retrieve-one.venzra-test.io"
    And I am logged in with the "customer-retrieve-one@venzra-test.io" account
    When I make a GET request to the API endpoint "/store/customer" as "customer"
    Then there should be a 200 response from the "customer" request that contains:
      | _id       | identity                             | addresses | status |
      | OBJECT_ID | customer-retrieve-one@venzra-test.io | ARRAY[0]  | ACTIVE |

  Scenario: Retrieve customer profile information (with addresses)
    Given the request origin headers are set to "customer-retrieve-one.venzra-test.io"
    And I am logged in with the "customer-retrieve-two@venzra-test.io" account
    When I make a GET request to the API endpoint "/store/customer" as "customer"
    Then there should be a 200 response from the "customer" request that contains:
      | _id       | identity                             | addresses | status |
      | OBJECT_ID | customer-retrieve-two@venzra-test.io | ARRAY[1]  | ACTIVE |
    And the response from the "customer" request has a "addresses" that contains rows:
      | _id       | addressee  | street | county | postalCode | country |
      | OBJECT_ID | Mr Address | Street | County | PO573OX    | GB      |
