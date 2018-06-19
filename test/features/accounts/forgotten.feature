@Accounts @AccountsRecovery
Feature: Begin the process of resetting a password for an existing account entry

  @Seed
  Scenario: Setup test data seed for feature
    And there are the following "accounts" records in the database
      | identity                         | password | status |
      | account-recovery@venzra-test.com | PASSWORD | ACTIVE |

  Scenario: A user that does not exist in the database will get an accepted response
    When I make a POST request to the API endpoint "/accounts/forgotten" as "forgotten" using:
      | identity                |
      | invalid@venzra-test.com |
    Then the status returned from the "forgotten" request should be 202

  Scenario: A user that does exist in the database will get an accepted response and the database record updated accordingly
    When I make a POST request to the API endpoint "/accounts/forgotten" as "forgotten" using:
      | identity                         |
      | account-recovery@venzra-test.com |
    Then the status returned from the "forgotten" request should be 202
    And the database record for "{{ accounts[1]._id }}" in the "accounts" table equals:
      | _id                   | identity                         | validation | terms     | status   | created   | updated   |
      | {{ accounts[1]._id }} | account-recovery@venzra-test.com | OBJECT     | DATE_TIME | RECOVERY | DATE_TIME | DATE_TIME |
