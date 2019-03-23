@Admin @Identity @IdentityActivation
Feature: Activation of a registered users account

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName               | status |
      | Identity Activation One | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                                 | validation                                                       | status     | subscription               |
      | identity-activation-one@venzra-test.io   | {"key":"aaaabbbbccccdddd", "expires":"2050-09-18T00:00:00.000Z"} | REGISTERED | null                       |
      | identity-activation-two@venzra-test.io   | {"key":"aaaabbbbccccdddd", "expires":"1980-09-18T00:00:00.000Z"} | REGISTERED | null                       |
      | identity-activation-three@venzra-test.io | {"key":"aaaabbbbccccdddd", "expires":"2050-09-18T00:00:00.000Z"} | RECOVERY   | {{ subscriptions[1]._id }} |

  Scenario: An incorrect account reference should return an error message
    Given I make a POST request to the API endpoint "/admin/identity/activate" as "activation" using:
      | id                       | password     | token            |
      | 000000000000000000000000 | VenzraTest$1 | aaaabbbbccccdddd |
    Then there should be a 400 error from the "activation" request that contains:
      | message             | detail |
      | Invalid credentials | []     |

  Scenario: An expired token should no longer allow activation to occur
    Given I make a POST request to the API endpoint "/admin/identity/activate" as "activation" using:
      | id                    | password     | token            |
      | {{ accounts[2]._id }} | VenzraTest$1 | aaaabbbbccccdddd |
    Then there should be a 400 error from the "activation" request that contains:
      | message             | detail |
      | Invalid credentials | []     |

  Scenario: An incorrect validation token should not allow activation to occur
    Given I make a POST request to the API endpoint "/admin/identity/activate" as "activation" using:
      | id                    | password     | token            |
      | {{ accounts[1]._id }} | VenzraTest$1 | ddddccccbbbbaaaa |
    Then there should be a 400 error from the "activation" request that contains:
      | message             | detail |
      | Invalid credentials | []     |

  Scenario: An expired key cannot activate an account
    Given I make a POST request to the API endpoint "/admin/identity/activate" as "activation" using:
      | id                    | password     | token            |
      | {{ accounts[1]._id }} | VenzraTest$1 | ddddccccbbbbaaaa |
    Then there should be a 400 error from the "activation" request that contains:
      | message             | detail |
      | Invalid credentials | []     |

  Scenario: Activate a registered user
    Given I make a POST request to the API endpoint "/admin/identity/activate" as "activation" using:
      | id                    | password     | token            |
      | {{ accounts[1]._id }} | VenzraTest$1 | aaaabbbbccccdddd |
    Then the status returned from the "activation" request should be 202
    When I am logged in with the "identity-activation-one@venzra-test.io" admin account
    And I make a GET request to the API endpoint "/admin/identity" as "account"
    Then there should be a 200 response from the "account" request that contains:
      | _id       | identity                               | status | subscription |
      | OBJECT_ID | identity-activation-one@venzra-test.io | ACTIVE | OBJECT_ID    |

  Scenario: Activate a recovery user
    Given I make a POST request to the API endpoint "/admin/identity/activate" as "activation" using:
      | id                    | password     | token            |
      | {{ accounts[3]._id }} | VenzraTest$1 | aaaabbbbccccdddd |
    Then the status returned from the "activation" request should be 202
    When I am logged in with the "identity-activation-three@venzra-test.io" admin account
    And I make a GET request to the API endpoint "/admin/identity" as "account"
    Then there should be a 200 response from the "account" request that contains:
      | _id       | identity                                 | status | subscription               |
      | OBJECT_ID | identity-activation-three@venzra-test.io | ACTIVE | {{ subscriptions[1]._id }} |
