@Admin @Webhooks @WebhooksStripe @WebhooksStripePlans
Feature: Manage webhooks sent by stripe to inform of plan creation and removal

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "plans" records in the database
      | reference                 | name                         | currency | price | interval | frequency |
      | WebhooksStripePlansDelete | Webhooks Stripe Plans Delete | gbp      | 100   | 1        | week      |

  Scenario: A stripe payload with an invalid signature is rejected
    Given I make a POST request to the API endpoint "/admin/webhooks/stripe" as "stripe" with the mock "stripe/plans/created-webhook.json"
    Then the status returned from the "stripe" request should be a 403 error

  Scenario: Receipt of a created plan webhook from stripe
    Given there is a stripe webhook signature for the mock payload "stripe/plans/created-webhook.json"
    When I make a POST request to the API endpoint "/admin/webhooks/stripe" as "stripe" with the mock "stripe/plans/created-webhook.json"
    Then there should be a 200 response from the "stripe" request that contains:
      | result    |
      | OBJECT_ID |

  Scenario: Receipt of a created plan webhook that has already created a plan is ignored
    Given there is a stripe webhook signature for the mock payload "stripe/plans/created-webhook.json"
    When I make a POST request to the API endpoint "/admin/webhooks/stripe" as "stripe" with the mock "stripe/plans/created-webhook.json"
    Then there should be a 200 response from the "stripe" request that contains:
      | result  |
      | skipped |

  Scenario: Receipt of a deleted plan webhook from stripe
    Given there is a stripe webhook signature for the mock payload "stripe/plans/deleted-webhook.json"
    When I make a POST request to the API endpoint "/admin/webhooks/stripe" as "stripe" with the mock "stripe/plans/deleted-webhook.json"
    Then there should be a 200 response from the "stripe" request that contains:
      | result    |
      | OBJECT_ID |

  Scenario: Receipt of a delete plan webhook that has been removed will return that it was skipped
    Given there is a stripe webhook signature for the mock payload "stripe/plans/deleted-webhook.json"
    When I make a POST request to the API endpoint "/admin/webhooks/stripe" as "stripe" with the mock "stripe/plans/deleted-webhook.json"
    Then there should be a 200 response from the "stripe" request that contains:
      | result  |
      | skipped |
