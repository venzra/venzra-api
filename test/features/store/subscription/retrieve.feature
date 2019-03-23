@Store @Subscription @SubscriptionRetrieve
Feature: Retrieval of subscription information for the current store

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                       | gateway                        | addons                                                               | contact                                     |
      | Store Subscription Retrieve One | { "publicKey": "pk_xxxxxxxx" } | [{ "name": "ABOUT", "value": 0 }, { "name": "CONTACT", "value": 0 }] | { "recipient": "no-reply@venzra-test.com" } |
      | Store Subscription Retrieve Two | {}                             | [{ "name": "LOCATION", "value": 0 }]                                 | { "recipient": "no-reply@venzra-test.com" } |

  Scenario: If there is no store then an error should occur
    Given the request origin headers are set to "store-subscription-retrieve-invalid.venzra-test.io"
    And I make a GET request to the API endpoint "/store/subscription" as "subscription"
    Then the status returned from the "subscription" request should be a 404 error

  Scenario: A valid store data set should be returned for a request
    Given the request origin headers are set to "store-subscription-retrieve-one.venzra-test.io"
    And I make a GET request to the API endpoint "/store/subscription" as "subscription"
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                      | storeName                       | features             | contact                                                   | gateway     | created   |
      | OBJECT_ID | store-subscription-retrieve-one | Store Subscription Retrieve One | ["ABOUT", "CONTACT"] | { "recipient": "no-reply@venzra-test.com", "fields": [] } | pk_xxxxxxxx | DATE_TIME |
    And there is a cookie called "vid" in the "subscription" response header

  Scenario: A store without a publicKey should still return without error
    Given the request origin headers are set to "store-subscription-retrieve-two.venzra-test.io"
    And I make a GET request to the API endpoint "/store/subscription" as "subscription"
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                      | storeName                       | features     | contact                                                   | created   |
      | OBJECT_ID | store-subscription-retrieve-two | Store Subscription Retrieve Two | ["LOCATION"] | { "recipient": "no-reply@venzra-test.com", "fields": [] } | DATE_TIME |
    And there is a cookie called "vid" in the "subscription" response header
