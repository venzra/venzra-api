@Accounts @AccountsRegistration
Feature: Access a list of plans that a user will be able to subscribe to after registration

  Scenario: Required fields missing should result in an error occurring
    When I make a POST request to the API endpoint "/accounts/registration" as "registration" using:
      | invalid     |
      | bad request |
    Then there should be a 400 error from the "registration" request that contains:
      | error       |
      | Bad Request |

  Scenario: Missing terms acceptance rejects creation of account
    When I make a POST request to the API endpoint "/accounts/registration" as "registration" using:
      | identity                        |
      | success@simulator.amazonses.com |
    Then there should be a 400 error from the "registration" request that contains:
      | error       |
      | Bad Request |

  Scenario: Ensure the required fields are returned correctly
    When I make a POST request to the API endpoint "/accounts/registration" as "registration" using:
      | identity                        | acceptTerms |
      | success@simulator.amazonses.com | true        |
    Then there should be a 200 response from the "registration" request that contains:
      | _id       | identity                        | terms     | status     | created   | updated   |
      | OBJECT_ID | success@simulator.amazonses.com | DATE_TIME | REGISTERED | DATE_TIME | DATE_TIME |

  Scenario: If an account has previously registered they can register again however they will be moved to a recovery state
    When I make a POST request to the API endpoint "/accounts/registration" as "registration" using:
      | identity                        | acceptTerms |
      | SUCCESS@SIMULATOR.AMAZONSES.COM | true        |
    Then there should be a 200 response from the "registration" request that contains:
      | _id       | identity                        | terms     | status   | created   | updated   |
      | OBJECT_ID | success@simulator.amazonses.com | DATE_TIME | RECOVERY | DATE_TIME | DATE_TIME |
