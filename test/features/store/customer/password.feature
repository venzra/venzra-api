@Store @Customer @CustomerPassword
Feature: Ability for a customer to change their password

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName             | status |
      | Customer Password One | ACTIVE |
      | Customer Password Two | ACTIVE |
    And there are the following "customers" records in the database
      | identity                             | password | status | subscription               |
      | customer-password-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |

  Scenario: The password request must contain the correct current password
    Given the request origin headers are set to "customer-password-one.venzra-test.io"
    And I am logged in with the "customer-password-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/customer/password" as "password" using:
      | current      |
      | VenzraTest$1 |
    Then there should be a 400 error from the "password" request that contains:
      | message           | detail                |
      | Validation failed | ["password required"] |

  Scenario: The password request must contain the correct current password
    Given the request origin headers are set to "customer-password-one.venzra-test.io"
    And I am logged in with the "customer-password-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/customer/password" as "password" using:
      | current      | password | confirmation |
      | VenzraTest$1 | Venzra   | Venzra       |
    Then there should be a 400 error from the "password" request that contains:
      | message           | detail                |
      | Validation failed | ["password strength"] |

  Scenario: The password request must contain the correct current password
    Given the request origin headers are set to "customer-password-one.venzra-test.io"
    And I am logged in with the "customer-password-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/customer/password" as "password" using:
      | current      | password     | confirmation |
      | VenzraTest$2 | VenzraTest$2 | VenzraTest$2 |
    Then there should be a 400 error from the "password" request that contains:
      | message           | detail              |
      | Validation failed | ["current invalid"] |

  Scenario: The password request must contain a confirmation matching the new password
    Given the request origin headers are set to "customer-password-one.venzra-test.io"
    And I am logged in with the "customer-password-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/customer/password" as "password" using:
      | current      | password     | confirmation |
      | VenzraTest$1 | VenzraTest$2 | VenzraTest$3 |
    Then there should be a 400 error from the "password" request that contains:
      | message           | detail                   |
      | Validation failed | ["confirmation invalid"] |

  Scenario: Sending a request to change a password is accepted
    Given the request origin headers are set to "customer-password-one.venzra-test.io"
    And I am logged in with the "customer-password-one@venzra-test.io" account
    When I make a POST request to the API endpoint "/store/customer/password" as "password" using:
      | current      | password     | confirmation |
      | VenzraTest$1 | VenzraTest$2 | VenzraTest$2 |
    Then the status returned from the "password" request should be 202
