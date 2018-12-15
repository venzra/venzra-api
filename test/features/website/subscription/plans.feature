@Website @Subscription @SubscriptionPlans
Feature: Access a list of plans that a user will be able to subscribe to after registration

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "plans" records in the database
      | reference          | name                 | currency | price | interval | frequency |
      | SubscriptionPlansA | Subscription Plans A | gbp      | 120   | 2        | week      |
      | SubscriptionPlansB | Subscription Plans B | eur      | 110   | 1        | month     |
      | SubscriptionPlansC | Subscription Plans C | usd      | 100   | 5        | day       |

  Scenario: Retrieve a list of plans
    When I make a GET request to the API endpoint "/website/subscription/plans" as "plans"
    Then there should be a 200 response from the "plans" request that contains:
      | list  | total  |
      | ARRAY | NUMBER |
    And there should be a 200 response from the "plans" request that has a "list" field and row 1 contains:
      | _id       | reference          | name                 | currency | price | interval | frequency |
      | OBJECT_ID | SubscriptionPlansC | Subscription Plans C | usd      | 100   | 5        | day       |
    And there should be a 200 response from the "plans" request that has a "list" field and row 2 contains:
      | _id       | reference          | name                 | currency | price | interval | frequency |
      | OBJECT_ID | SubscriptionPlansB | Subscription Plans B | eur      | 110   | 1        | month     |
    And there should be a 200 response from the "plans" request that has a "list" field and row 3 contains:
      | _id       | reference          | name                 | currency | price | interval | frequency |
      | OBJECT_ID | SubscriptionPlansA | Subscription Plans A | gbp      | 120   | 2        | week      |
