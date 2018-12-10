@Admin @Subscription @SubscriptionContact
Feature: Management of customer contact requirements

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                      | status |
      | Admin Subscription Contact One | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                                | password | subscription               | status |
      | subscription-contact-one@venzra-test.io | PASSWORD | {{ subscriptions[1]._id }} | ACTIVE |

  Scenario: If setting contact information then recipient email address is required
    Given I am logged in with the "subscription-contact-one@venzra-test.io" admin account
    When I make an empty POST request to the API endpoint "/admin/subscription/contact" as "subscription"
    Then there should be a 400 error from the "subscription" request that contains:
      | message           | detail                 |
      | Validation failed | ["recipient required"] |

  Scenario: If setting contact information then it is saved
    Given I am logged in with the "subscription-contact-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/subscription/contact" as "subscription" using:
      | recipient               | fields                     |
      | no-reply@venzra-test.io | ["NAME", "EMAIL", "PHONE"] |
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                     | additionalDomains | storeName                      | transactions                  | addons   | contact | status |
      | OBJECT_ID | admin-subscription-contact-one | []                | Admin Subscription Contact One | { "base": 10, "rate": 0.046 } | ARRAY[0] | OBJECT  | ACTIVE |
    And the response path "contact" from the "subscription" request contains:
      | recipient               | fields                     |
      | no-reply@venzra-test.io | ["NAME", "EMAIL", "PHONE"] |

  Scenario: To replace contact information all details are required
    Given I am logged in with the "subscription-contact-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/subscription/contact" as "subscription" using:
      | recipient                | fields                                                                |
      | automated@venzra-test.io | ["NAME", "COMPANY", "EMAIL", "PHONE", "SUBJECT", "REASON", "MESSAGE"] |
    Then there should be a 200 response from the "subscription" request that contains:
      | _id       | domainName                     | additionalDomains | storeName                      | transactions                  | addons   | contact | status |
      | OBJECT_ID | admin-subscription-contact-one | []                | Admin Subscription Contact One | { "base": 10, "rate": 0.046 } | ARRAY[0] | OBJECT  | ACTIVE |
    And the response path "contact" from the "subscription" request contains:
      | recipient                | fields                                                                |
      | automated@venzra-test.io | ["NAME", "COMPANY", "EMAIL", "PHONE", "SUBJECT", "REASON", "MESSAGE"] |
