@Store @Identity @IdentityLogout
Feature: Perform a logout command that removes any customer authentication token

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName           | status |
      | Identity Logout One | ACTIVE |
    Given there are the following "customers" records in the database
      | identity                           | password | status | subscription               |
      | identity-logout-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |

  Scenario: Logging out an customer that has previously logged in should be a success
    Given the request origin headers are set to "identity-logout-one.venzra-test.io"
    And I am logged in with the "identity-logout-one@venzra-test.io" store account
    When I make a POST request to the API endpoint "/store/identity/logout" as "logout" using:
      | logout |
      | true   |
    Then the status returned from the "logout" request should be 202
    And there is a deleted cookie called "jwt" in the "logout" response header

  Scenario: Logging out when a customer is not actually logged in
    Given the request origin headers are set to "identity-logout-one.venzra-test.io"
    When I make a POST request to the API endpoint "/store/identity/logout" as "logout" using:
      | logout |
      | true   |
    Then the status returned from the "logout" request should be 202
    And there is a deleted cookie called "jwt" in the "logout" response header
