@Admin @Subscription @SubscriptionAddons
Feature: Management of addons for a subscription

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                     | status |
      | Admin Subscription Addons One | TRIAL  |
    And there are the following "accounts" records in the database
      | identity                               | password | subscription               | status |
      | subscription-addons-one@venzra-test.io | PASSWORD | {{ subscriptions[1]._id }} | ACTIVE |

  Scenario: If no update information is provided then the request is ignored
    Given I am logged in with the "subscription-addons-one@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/subscription/add-ons" as "subscription"
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                    | additionalDomains | storeName                     | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-addons-one | []                | Admin Subscription Addons One | { "base": 10, "rate": 0.046 } | ARRAY[0] | TRIAL  |

  Scenario: If adding an addon to the subscription record
    Given I am logged in with the "subscription-addons-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/subscription/add-ons" as "subscription" using:
      | op  | path | value     |
      | add | name | ABOUT     |
      | add | name | CAREERS   |
      | add | name | CONTACT   |
      | add | name | LOCATIONS |
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                    | additionalDomains | storeName                     | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-addons-one | []                | Admin Subscription Addons One | { "base": 10, "rate": 0.046 } | ARRAY[4] | TRIAL  |
    And the response path "addons" from the "subscription" request contains:
      | name      | activated | value |
      | ABOUT     | DATE_TIME | 0     |
      | CAREERS   | DATE_TIME | 0     |
      | CONTACT   | DATE_TIME | 0     |
      | LOCATIONS | DATE_TIME | 0     |

  Scenario: If removing an addon from the subscription record
    Given I am logged in with the "subscription-addons-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/subscription/add-ons" as "subscription" using:
      | op     | path | value   |
      | remove | name | ABOUT   |
      | remove | name | CONTACT |
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                    | additionalDomains | storeName                     | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-addons-one | []                | Admin Subscription Addons One | { "base": 10, "rate": 0.046 } | ARRAY[2] | TRIAL  |
    And the response path "addons" from the "subscription" request contains:
      | name      | activated | value |
      | CAREERS   | DATE_TIME | 0     |
      | LOCATIONS | DATE_TIME | 0     |

  Scenario: Performing multiple add and remove commands concludes correctly based on order of request operations
    Given I am logged in with the "subscription-addons-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/subscription/add-ons" as "subscription" using:
      | op     | path | value     |
      | add    | name | ABOUT     |
      | add    | name | DELIVERY  |
      | remove | name | CONTACT   |
      | remove | name | DELIVERY  |
      | add    | name | contact   |
      | remove | name | LOCATIONS |
      | add    | name | ABOUT     |
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                    | additionalDomains | storeName                     | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-addons-one | []                | Admin Subscription Addons One | { "base": 10, "rate": 0.046 } | ARRAY[3] | TRIAL  |
    And the response path "addons" from the "subscription" request contains:
      | name    | activated | value |
      | ABOUT   | DATE_TIME | 0     |
      | CAREERS | DATE_TIME | 0     |
      | CONTACT | DATE_TIME | 0     |
