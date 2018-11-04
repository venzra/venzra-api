@Store @Identity @IdentityLogin
Feature: Ability for a user to authenticate and gain a login token to use the API further

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName          | status | additionalDomains                                                    |
      | Identity Login One | ACTIVE | ["additional-one.venzra-test.com", "additional-two.venzra-test.com"] |
    Given there are the following "customers" records in the database
      | identity                            | password | lock           | status   | subscription               |
      | identity-login-one@venzra-test.io   | PASSWORD | {"failures":0} | RECOVERY | {{ subscriptions[1]._id }} |
      | identity-login-two@venzra-test.io   | PASSWORD | {"failures":0} | ACTIVE   | {{ subscriptions[1]._id }} |
      | identity-login-three@venzra-test.io | PASSWORD | {"failures":5} | LOCKED   | {{ subscriptions[1]._id }} |

  Scenario: Login without credentials
    Given the request origin headers are set to "identity-login-one.venzra-test.io"
    When I make an empty POST request to the API endpoint "/store/identity/login" as "login"
    Then there should be a 400 error from the "login" request that contains:
      | message           | detail                                     |
      | Validation failed | ["identity required", "password required"] |

  Scenario: Login with an UNKNOWN customer will register the user
    Given the request origin headers are set to "identity-login-one.venzra-test.io"
    And I make a POST request to the API endpoint "/store/identity/login" as "login" using:
      | identity                              | password     |
      | identity-login-unknown@venzra-test.io | VenzraTest$1 |
    Then the status returned from the "login" request should be 202
    And there is a cookie called "jwt" in the "login" response header

  Scenario: Login with a RECOVERY customer
    Given the request origin headers are set to "identity-login-one.venzra-test.io"
    And I make a POST request to the API endpoint "/store/identity/login" as "login" using:
      | identity                          | password     |
      | identity-login-one@venzra-test.io | VenzraTest$1 |
    Then the status returned from the "login" request should be 202
    And there is a cookie called "jwt" in the "login" response header

  Scenario: Incorrect password with an ACTIVE customer
    Given the request origin headers are set to "identity-login-one.venzra-test.io"
    And I make a POST request to the API endpoint "/store/identity/login" as "login" using:
      | identity                          | password          |
      | identity-login-two@venzra-test.io | IncorrectPassword |
    Then there should be a 400 error from the "login" request that contains:
      | message             | detail |
      | Invalid credentials | []     |

  Scenario: Login with an ACTIVE customer (lowercase)
    Given the request origin headers are set to "identity-login-one.venzra-test.io"
    And I make a POST request to the API endpoint "/store/identity/login" as "login" using:
      | identity                          | password     |
      | identity-login-two@venzra-test.io | VenzraTest$1 |
    Then the status returned from the "login" request should be 202
    And there is a cookie called "jwt" in the "login" response header

  Scenario: Login with an ACTIVE customer (uppercase)
    Given the request origin headers are set to "identity-login-one.venzra-test.io"
    And I make a POST request to the API endpoint "/store/identity/login" as "login" using:
      | identity                          | password     |
      | IDENTITY-LOGIN-TWO@VENZRA-TEST.IO | VenzraTest$1 |
    Then the status returned from the "login" request should be 202
    And there is a cookie called "jwt" in the "login" response header

  Scenario: Login with an ACTIVE customer (additional domain one)
    Given the request origin headers are set to "additional-one.venzra-test.com"
    And I make a POST request to the API endpoint "/store/identity/login" as "login" using:
      | identity                          | password     |
      | identity-login-two@venzra-test.io | VenzraTest$1 |
    Then the status returned from the "login" request should be 202
    And there is a cookie called "jwt" in the "login" response header

  Scenario: Login with an ACTIVE customer (additional domain two)
    Given the request origin headers are set to "additional-two.venzra-test.com"
    And I make a POST request to the API endpoint "/store/identity/login" as "login" using:
      | identity                          | password     |
      | identity-login-two@venzra-test.io | VenzraTest$1 |
    Then the status returned from the "login" request should be 202
    And there is a cookie called "jwt" in the "login" response header

  Scenario: Login with a LOCKED customer
    Given the request origin headers are set to "identity-login-one.venzra-test.io"
    And I make a POST request to the API endpoint "/store/identity/login" as "login" using:
      | identity                            | password     |
      | identity-login-three@venzra-test.io | VenzraTest$1 |
    Then there should be a 400 error from the "login" request that contains:
      | message             | detail |
      | Invalid credentials | []     |
