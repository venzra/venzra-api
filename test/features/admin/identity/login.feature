@Admin @Identity @IdentityLogin
Feature: Ability for a user to authenticate and gain a login token to use the API further

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "accounts" records in the database
      | identity                            | password | lock           | status     |
      | identity-login-one@venzra-test.io   | PASSWORD | {"failures":0} | REGISTERED |
      | identity-login-two@venzra-test.io   | PASSWORD | {"failures":0} | RECOVERY   |
      | identity-login-three@venzra-test.io | PASSWORD | {"failures":0} | ACTIVE     |
      | identity-login-four@venzra-test.io  | PASSWORD | {"failures":5} | LOCKED     |

  Scenario: Login without credentials
    Given I make an empty POST request to the API endpoint "/admin/identity/login" as "login"
    Then there should be a 400 error from the "login" request that contains:
      | message             | detail |
      | Invalid credentials | []     |

  Scenario: Login with an UNKNOWN account
    Given I make a POST request to the API endpoint "/admin/identity/login" as "login" using:
      | identity                       | password     |
      | unknown-account@venzra-test.io | VenzraTest$1 |
    Then there should be a 400 error from the "login" request that contains:
      | message             | detail |
      | Invalid credentials | []     |

  Scenario: Login with a REGISTERED account
    Given I make a POST request to the API endpoint "/admin/identity/login" as "login" using:
      | identity                          | password     |
      | identity-login-one@venzra-test.io | VenzraTest$1 |
    Then there should be a 400 error from the "login" request that contains:
      | message             | detail |
      | Invalid credentials | []     |

  Scenario: Login with a RECOVERY account
    Given I make a POST request to the API endpoint "/admin/identity/login" as "login" using:
      | identity                          | password     |
      | identity-login-two@venzra-test.io | VenzraTest$1 |
    Then the status returned from the "login" request should be 202
    And there is a cookie called "jwt" in the "login" response header

  Scenario: Incorrect password with an ACTIVE account
    Given I make a POST request to the API endpoint "/admin/identity/login" as "login" using:
      | identity                            | password          |
      | identity-login-three@venzra-test.io | IncorrectPassword |
    Then there should be a 400 error from the "login" request that contains:
      | message             | detail |
      | Invalid credentials | []     |

  Scenario: Login with an ACTIVE account (lowercase)
    Given I make a POST request to the API endpoint "/admin/identity/login" as "login" using:
      | identity                            | password     |
      | identity-login-three@venzra-test.io | VenzraTest$1 |
    Then the status returned from the "login" request should be 202
    And there is a cookie called "jwt" in the "login" response header

  Scenario: Login with an ACTIVE account (uppercase)
    Given I make a POST request to the API endpoint "/admin/identity/login" as "login" using:
      | identity                            | password     |
      | IDENTITY-LOGIN-THREE@VENZRA-TEST.IO | VenzraTest$1 |
    Then the status returned from the "login" request should be 202
    And there is a cookie called "jwt" in the "login" response header

  Scenario: Login with a LOCKED account
    Given I make a POST request to the API endpoint "/admin/identity/login" as "login" using:
      | identity                           | password     |
      | identity-login-four@venzra-test.io | VenzraTest$1 |
    Then there should be a 400 error from the "login" request that contains:
      | message             | detail |
      | Invalid credentials | []     |
