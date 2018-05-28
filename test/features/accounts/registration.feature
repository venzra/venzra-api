@Accounts @AccountsRegistration
Feature: Access a list of plans that a user will be able to subscribe to after registration

  Scenario: Required fields missing should result in an error occurring
    When I make a POST request to the API endpoint "/accounts/registration" as "registration" using:
      | invalid     |
      | bad request |
    Then there should be a 400 error from the "registration" request that contains:
      | error       |
      | Bad Request |

  Scenario: Ensure the required fields are returned correctly
    When I make a POST request to the API endpoint "/accounts/registration" as "registration" using:
      | identity                        |
      | success@simulator.amazonses.com |
    Then there should be a 200 response from the "registration" request that contains:
      | _id       | identity                        | status     | created   | updated   |
      | OBJECT_ID | success@simulator.amazonses.com | REGISTERED | DATE_TIME | DATE_TIME |

  Scenario: If an account has previously registered they can register again however they will be moved to a recovery state
    When I make a POST request to the API endpoint "/accounts/registration" as "registration" using:
      | identity                        |
      | SUCCESS@SIMULATOR.AMAZONSES.COM |
    Then there should be a 200 response from the "registration" request that contains:
      | _id       | identity                        | status   | created   | updated   |
      | OBJECT_ID | success@simulator.amazonses.com | RECOVERY | DATE_TIME | DATE_TIME |
