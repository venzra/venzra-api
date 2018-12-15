@Admin @Webhooks @WebhooksConnect @WebhooksConnectAccount
Feature: Manage connect hook sent by stripe to inform of account association or removal

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                          | gateway                              | status |
      | Admin Webhooks Connect Account One | { "account": "acct_xxxxxxxxxxxxxx" } | ACTIVE |
      | Admin Webhooks Connect Account Two | { "account": "acct_yyyyyyyyyyyyyy" } | ACTIVE |

  Scenario: A stripe payload with an invalid signature is rejected
    Given I make a POST request to the API endpoint "/admin/webhooks/connect" as "connect" with the mock "stripe/connect/account/deactivate-webhook.json"
    Then the status returned from the "connect" request should be a 403 error

  Scenario: Receipt of a successful deactivation request from Stripe
    Given there is a connect webhook signature for the mock payload "stripe/connect/account/deactivate-webhook.json"
    When I make a POST request to the API endpoint "/admin/webhooks/connect" as "connect" with the mock "stripe/connect/account/deactivate-webhook.json"
    Then there should be a 200 response from the "connect" request that contains:
      | result    |
      | OBJECT_ID |

  Scenario: Receipt of a deactivation request from Stripe that has already been deactivated
    Given there is a connect webhook signature for the mock payload "stripe/connect/account/deactivate-webhook.json"
    When I make a POST request to the API endpoint "/admin/webhooks/connect" as "connect" with the mock "stripe/connect/account/deactivate-webhook.json"
    Then there should be a 200 response from the "connect" request that contains:
      | result  |
      | skipped |
