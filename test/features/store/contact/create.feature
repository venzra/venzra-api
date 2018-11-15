@Store @Contact @ContactCreate
Feature: Ability to send a contact message

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                | contact                                                                             | status |
      | Store Contact Create One | { "recipient": "joe.bloggs@venza-test.io", "fields": ["NAME", "EMAIL", "MESSAGE"] } | ACTIVE |
      | Store Contact Create Two | { "recipient": "joe.bloggs@venza-test.io", "fields": ["NAME", "EMAIL", "MESSAGE"] } | ACTIVE |

  Scenario: Sending a message via the contact endpoint
    Given the request origin headers are set to "store-contact-create-one.venzra-test.io"
    When I make an empty POST request to the API endpoint "/store/contact" as "contact"
    Then there should be a 400 error from the "contact" request that contains:
      | message           | detail                                                      |
      | Validation failed | ["fullName required", "email required", "message required"] |

  Scenario: Sending a message via the contact endpoint
    Given the request origin headers are set to "store-contact-create-one.venzra-test.io"
    And there is a POST consumer at "https://email.eu-west-1.amazonaws.com" that will return status 200
    When I make a POST request to the API endpoint "/store/contact" as "contact" using:
      | fullName   | email                     | message           |
      | John Smith | john.smith@venzra-test.io | Automated message |
    Then the status returned from the "contact" request should be 202

  Scenario: Sending a message via the contact endpoint
    Given the request origin headers are set to "store-contact-create-one.venzra-test.io"
    And there is a POST consumer at "https://email.eu-west-1.amazonaws.com" that will return "aws/ses-failure.xml" with status 400
    When I make a POST request to the API endpoint "/store/contact" as "contact" using:
      | fullName   | email                     | message           |
      | John Smith | john.smith@venzra-test.io | Automated message |
    Then there should be a 503 error from the "contact" request that contains:
      | message           | detail |
      | Third party error | []     |
