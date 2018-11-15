@Admin @Identity @IdentityLogout
Feature: Perform a logout command that removes any account authentication token

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "accounts" records in the database
      | identity                           | password | status |
      | identity-logout-one@venzra-test.io | PASSWORD | ACTIVE |

  Scenario: Logging out an account that has previously logged in should be a success
    Given I am logged in with the "identity-logout-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/identity/logout" as "logout" using:
      | logout |
      | true   |
    Then the status returned from the "logout" request should be 202
    And there is a deleted cookie called "jwt" in the "logout" response header
