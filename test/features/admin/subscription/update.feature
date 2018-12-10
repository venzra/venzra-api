@Admin @Subscription @SubscriptionUpdate
Feature: Updating a new subscription via patch requests

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                     | strapline                    | additionalDomains              |
      | Admin Subscription Update One | Automated subscription entry | ["domain-two@venzra-test.com"] |
    And there are the following "images" records in the database
      | subscription               | name                       | usage | size |
      | {{ subscriptions[1]._id }} | SubscriptionUpdate Image A | icon  | 1024 |
      | {{ subscriptions[1]._id }} | SubscriptionUpdate Image B | logo  | 1024 |
    And there are the following "accounts" records in the database
      | identity                               | password | status | subscription               |
      | subscription-update-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |

  Scenario: If no update information is provided then the request is ignored
    Given I am logged in with the "subscription-update-one@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/subscription" as "subscription"
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                    | additionalDomains              | storeName                     | strapline                    | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-update-one | ["domain-two@venzra-test.com"] | Admin Subscription Update One | Automated subscription entry | { "base": 10, "rate": 0.046 } | ARRAY[0] | TRIAL  |

  Scenario: It should not be possible to set an empty store name value
    Given I am logged in with the "subscription-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/subscription" as "subscription" using:
      | op      | path      | value |
      | replace | storeName |       |
    Then there should be a 400 error from the "subscription" request that contains:
      | message           | detail                 |
      | Validation failed | ["storeName required"] |

  Scenario: Store name should be at least 3 characters
    Given I am logged in with the "subscription-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/subscription" as "subscription" using:
      | op      | path      | value |
      | replace | storeName | xx    |
    Then there should be a 400 error from the "subscription" request that contains:
      | message           | detail                  |
      | Validation failed | ["storeName minlength"] |

#  Scenario: Store additional domains can be cleared
#    Given I am logged in with the "subscription-update-one@venzra-test.io" admin account
#    When I make a PATCH request to the API endpoint "/admin/subscription" as "subscription" using:
#      | op      | path              | value |
#      | replace | additionalDomains | []    |
#    Then there should be a 200 response from the "subscription" request that contains:
#      | _id       | domainName                  | additionalDomains | storeName                   | strapline                  | icon                        | logo                        | theme  | transactions                  | addons   | status |
#      | OBJECT_ID | subscription-update-updated | []                | Subscription Update Updated | Updated subscription entry | OBJECT[_id,name,usage,path] | OBJECT[_id,name,usage,path] | OBJECT | { "base": 10, "rate": 0.046 } | ARRAY[0] | TRIAL  |

  Scenario: Update an existing account subscription record
    Given I am logged in with the "subscription-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/subscription" as "subscription" using:
      | op      | path              | value                                                        |
      | replace | storeName         | Admin Subscription Update Updated                            |
      | replace | strapline         | Updated subscription entry                                   |
      | replace | additionalDomains | ["domain-one@venzra-test.com", "domain-two@venzra-test.com"] |
      | replace | icon              | {{ images[1]._id }}                                          |
      | replace | logo              | {{ images[2]._id }}                                          |
      | replace | theme             | { "color": "Orange" }                                        |
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                        | additionalDomains                                            | storeName                         | strapline                  | icon                        | logo                        | theme  | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-update-updated | ["domain-one@venzra-test.com", "domain-two@venzra-test.com"] | Admin Subscription Update Updated | Updated subscription entry | OBJECT[_id,name,usage,path] | OBJECT[_id,name,usage,path] | OBJECT | { "base": 10, "rate": 0.046 } | ARRAY[0] | TRIAL  |
    And the response path "icon" from the "subscription" request contains:
      | _id                 | name                       | usage | path                                                    |
      | {{ images[1]._id }} | SubscriptionUpdate Image A | icon  | {{ subscriptions[1]._id }}/icon/{{ images[1]._id }}.png |
    And the response path "logo" from the "subscription" request contains:
      | _id                 | name                       | usage | path                                                    |
      | {{ images[2]._id }} | SubscriptionUpdate Image B | logo  | {{ subscriptions[1]._id }}/logo/{{ images[2]._id }}.png |
    And the response path "theme" from the "subscription" request contains:
      | color  |
      | orange |
