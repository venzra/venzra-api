@Admin @Subscription @SubscriptionGateway
Feature: Creation of a new subscription gateway

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                     | status |
      | Admin Subscription Create One | TRIAL  |
    And there are the following "accounts" records in the database
      | identity                               | password | subscription               | status |
      | subscription-create-one@venzra-test.io | PASSWORD | {{ subscriptions[1]._id }} | ACTIVE |

  Scenario: A missing email and stripe bank token will result in an error
    Given I am logged in with the "subscription-create-one@venzra-test.io" admin account
    When I make an empty POST request to the API endpoint "/admin/subscription/gateway" as "gateway"
    Then there should be a 400 error from the "gateway" request that contains:
      | message           | detail                 |
      | Validation failed | ["reference required"] |

  Scenario: Handle a rejection from stripe occurring when attempting to create a subscription
    Given I am logged in with the "subscription-create-one@venzra-test.io" admin account
    And there is a POST consumer at "https://connect.stripe.com" for "/oauth/token" that will return "stripe/connect/account/create-invalid.json" with status 400
    When I make a POST request to the API endpoint "/admin/subscription/gateway" as "gateway" using:
      | reference                           |
      | ac_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |
    Then there should be a 503 error from the "gateway" request that contains:
      | message               | detail |
      | Payment gateway error | []     |

  Scenario: Sending a valid request will create subscription payment data
    Given I am logged in with the "subscription-create-one@venzra-test.io" admin account
    And there is a POST consumer at "https://connect.stripe.com" for "/oauth/token" that will return "stripe/connect/account/create-success.json" with status 200
    When I make a POST request to the API endpoint "/admin/subscription/gateway" as "gateway" using:
      | reference                           |
      | ac_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |
    Then there should be a 200 response from the "gateway" request that contains:
      | _id       | domainName                    | additionalDomains | storeName                     | gateway | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-create-one | []                | Admin Subscription Create One | OBJECT  | { "base": 10, "rate": 0.046 } | ARRAY[0] | ACTIVE |
    And the response path "gateway" from the "gateway" request contains:
      | account               | modified  |
      | acct_xxxxxxxxxxxxxxxx | DATE_TIME |

  Scenario: Sending a second request will not call to stripe or change / overwrite subscription information
    Given I am logged in with the "subscription-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/subscription/gateway" as "gateway" using:
      | reference                           |
      | ac_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |
    Then there should be a 200 response from the "gateway" request that contains:
      | _id       | domainName                    | additionalDomains | storeName                     | gateway | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-create-one | []                | Admin Subscription Create One | OBJECT  | { "base": 10, "rate": 0.046 } | ARRAY[0] | ACTIVE |
    And the response path "gateway" from the "gateway" request contains:
      | account               | modified  |
      | acct_xxxxxxxxxxxxxxxx | DATE_TIME |
