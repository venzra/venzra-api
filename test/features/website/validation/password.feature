@Website @Validation @ValidationPassword
Feature: Validation of a password format

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName               | status |
      | Validation Password One | ACTIVE |

  Scenario: An empty request to validate a password returns a message
    Given the request origin headers are set to "validation-password-one.venzra-test.io"
    When I make an empty POST request to the API endpoint "/website/validation/password" as "validation"
    Then there should be a 200 response from the "validation" request that contains:
      | score | message                               |
      | 0     | Use a few words, avoid common phrases |

  Scenario: A commonly used password fails validation
    Given the request origin headers are set to "validation-password-one.venzra-test.io"
    When I make a POST request to the API endpoint "/website/validation/password" as "validation" using:
      | password |
      | password |
    Then there should be a 200 response from the "validation" request that contains:
      | score | message                          |
      | 0     | This is a top-10 common password |

  Scenario: A less common weak password receives a low score
    Given the request origin headers are set to "validation-password-one.venzra-test.io"
    When I make a POST request to the API endpoint "/website/validation/password" as "validation" using:
      | password      |
      | MyPassword123 |
    Then there should be a 200 response from the "validation" request that contains:
      | score | message                                     |
      | 1     | This is similar to a commonly used password |

  Scenario: A more complex password with low entropy will score slightly better
    Given the request origin headers are set to "validation-password-one.venzra-test.io"
    When I make a POST request to the API endpoint "/website/validation/password" as "validation" using:
      | password |
      | Venzra$1 |
    Then there should be a 200 response from the "validation" request that contains:
      | score | message                                             |
      | 2     | Add another word or two. Uncommon words are better. |

  Scenario: A longer word using 2 works achieves a higher levels of entropy
    Given the request origin headers are set to "validation-password-one.venzra-test.io"
    When I make a POST request to the API endpoint "/website/validation/password" as "validation" using:
      | password   |
      | VenzraTest |
    Then there should be a 200 response from the "validation" request that contains:
      | score |
      | 3     |

  Scenario: A password using a mix of characters and numbers is valid and scores well
    Given the request origin headers are set to "validation-password-one.venzra-test.io"
    When I make a POST request to the API endpoint "/website/validation/password" as "validation" using:
      | password     |
      | VenzraTest$1 |
    Then there should be a 200 response from the "validation" request that contains:
      | score |
      | 4     |
