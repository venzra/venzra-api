@Website @Support @SupportContact
Feature: Sending of emails from contact requests

  Scenario: Required fields missing should result in an error occurring
    When I make a POST request to the API endpoint "/website/support/contact" as "contact" using:
      | invalid     |
      | bad request |
    Then there should be a 400 error from the "contact" request that contains:
      | message           | detail                                                                               |
      | Validation failed | [ "alias required", "emailAddress required", "reason required", "message required" ] |

  Scenario: Valid request body will result in an email being sent correctly
    Given there is a POST consumer at "https://email.eu-west-1.amazonaws.com" that will return status 200
    When I make a POST request to the API endpoint "/website/support/contact" as "contact" using:
      | alias     | emailAddress                    | reason         | message                            |
      | Automated | support-contact@venzra-test.com | Automated Test | Message content for automated test |
    Then the status returned from the "contact" request should be 202
