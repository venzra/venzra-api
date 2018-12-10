@Admin @Subscription @SubscriptionPayment
Feature: Creation of a new subscription payment

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                      | payment                                                                                     | status |
      | Admin Subscription Payment One |                                                                                             | TRIAL  |
      | Admin Subscription Payment Two | { "customer": "cus_yyyyyyyyyyyyyy", "term" : "2050-09-18T13:30:00Z", "status": "CANCELED" } | ACTIVE |

    And there are the following "accounts" records in the database
      | identity                                | password | subscription               | status |
      | subscription-payment-one@venzra-test.io | PASSWORD | {{ subscriptions[1]._id }} | ACTIVE |
      | subscription-payment-two@venzra-test.io | PASSWORD | {{ subscriptions[2]._id }} | ACTIVE |

  Scenario: A missing email and stripe bank token will result in an error
    Given I am logged in with the "subscription-payment-one@venzra-test.io" admin account
    When I make an empty POST request to the API endpoint "/admin/subscription/payment" as "payment"
    Then there should be a 400 error from the "payment" request that contains:
      | message           | detail                                                |
      | Validation failed | ["email required", "plan required", "token required"] |

  Scenario: Handle a rejection from stripe occurring when attempting to create a subscription
    Given I am logged in with the "subscription-payment-one@venzra-test.io" admin account
    And there is a POST consumer at "https://api.stripe.com" for "/v1/customers" that will return "stripe/customer/create-invalid.json" with status 400
    When I make a POST request to the API endpoint "/admin/subscription/payment" as "payment" using:
      | email                                       | plan | token                                    |
      | subscription-payment-success@venzra-test.io | TEST | { "id": "tok_xxxxxxxxxxxxxxxxxxxxxxxx" } |
    Then the status returned from the "payment" request should be a 500 error

  Scenario: Sending a valid request will create a subscription
    Given I am logged in with the "subscription-payment-one@venzra-test.io" admin account
    And there is a POST consumer at "https://api.stripe.com" for "/v1/customers" that will return "stripe/customer/create-success.json" with status 200
    When I make a POST request to the API endpoint "/admin/subscription/payment" as "payment" using:
      | email                                       | plan | token                                    |
      | subscription-payment-success@venzra-test.io | TEST | { "id": "tok_xxxxxxxxxxxxxxxxxxxxxxxx" } |
    Then there should be a 200 response from the "payment" request that contains:
      | _id       | domainName                     | additionalDomains | storeName                      | payment | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-payment-one | []                | Admin Subscription Payment One | OBJECT  | { "base": 10, "rate": 0.021 } | ARRAY[0] | TRIAL  |
    And the response path "payment" from the "payment" request contains:
      | customer           | subscription       | package | price  | term      | status |
      | cus_xxxxxxxxxxxxxx | sub_xxxxxxxxxxxxxx | TEST    | OBJECT | DATE_TIME | ACTIVE |
    And the response path "payment.price" from the "payment" request contains:
      | currency | quantity | value |
      | gbp      | 20       | 125   |

  Scenario: For a canceled subscription it is possible to attach a new subscription without creating a new customer record
    Given I am logged in with the "subscription-payment-two@venzra-test.io" admin account
    And there is a POST consumer at "https://api.stripe.com" for "/v1/customers" that will return "stripe/subscriptions/create-success.json" with status 200
    When I make a POST request to the API endpoint "/admin/subscription/payment" as "payment" using:
      | email                                       | plan | token                                    |
      | subscription-payment-restore@venzra-test.io | TEST | { "id": "tok_xxxxxxxxxxxxxxxxxxxxxxxx" } |
    Then there should be a 200 response from the "payment" request that contains:
      | _id       | domainName                     | additionalDomains | storeName                      | payment | transactions                  | addons   | status |
      | OBJECT_ID | admin-subscription-payment-two | []                | Admin Subscription Payment Two | OBJECT  | { "base": 10, "rate": 0.021 } | ARRAY[0] | ACTIVE |
    And the response path "payment" from the "payment" request contains:
      | customer           | subscription       | package | price  | term      | status |
      | cus_yyyyyyyyyyyyyy | sub_yyyyyyyyyyyyyy | TEST    | OBJECT | DATE_TIME | ACTIVE |
    And the response path "payment.price" from the "payment" request contains:
      | currency | quantity | value |
      | gbp      | 20       | 125   |
