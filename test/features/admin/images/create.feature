@Admin @Images @ImagesCreate
Feature: Creation of images to be used by subscriptions and stored on S3

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName               | strapline                    |
      | Admin Images Create One | Automated subscription entry |
      | Admin Images Create Two | Automated subscription entry |
    And there are the following "accounts" records in the database
      | identity                         | password | status | subscription               |
      | images-create-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | images-create-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |

  Scenario: An empty request to create an image fails validation
    Given I am logged in with the "images-create-one@venzra-test.io" admin account
    When I make an empty POST request to the API endpoint "/admin/images" as "image"
    Then there should be a 400 error from the "image" request that contains:
      | message           | detail           |
      | Validation failed | ["body invalid"] |

  Scenario: Sending request body without meta information in query parameters fails validation
    Given I am logged in with the "images-create-one@venzra-test.io" admin account
    When I make a binary data POST request to the API endpoint "/admin/images" as "image" with image data:
      | width | height | format |
      | 512   | 512    | png    |
    Then there should be a 400 error from the "image" request that contains:
      | message           | detail                              |
      | Validation failed | ["name required", "usage required"] |

  Scenario: An image request that is too large will fail to be accepted
    Given I am logged in with the "images-create-one@venzra-test.io" admin account
    When I make a binary data POST request to the API endpoint "/admin/images?name=too-big.png&usage=feature" as "image" with image data:
      | width | height | format |
      | 2048  | 2048   | png    |
    Then there should be a 413 error from the "image" request that contains:
      | message                    | detail                 |
      | Request limit is: 2048 KiB | ["Received: 2803 KiB"] |

  Scenario: Sending a valid request to create a "feature" image will resize and save the image
    Given I am logged in with the "images-create-one@venzra-test.io" admin account
    And there is a PUT consumer at "https://s3.eu-west-1.amazonaws.com" that will return status 400
    When I make a binary data POST request to the API endpoint "/admin/images?name=aws-error.png&usage=feature" as "image" with image data:
      | width | height | format |
      | 512   | 512    | png    |
    Then there should be a 503 error from the "image" request that contains:
      | message           | detail |
      | Third party error | []     |

  Scenario: Sending a valid request to create a "feature" image will resize and save the image
    Given I am logged in with the "images-create-one@venzra-test.io" admin account
    And there is a PUT consumer at "https://s3.eu-west-1.amazonaws.com" that will return status 200
    When I make a binary data POST request to the API endpoint "/admin/images?name=test-one.png&usage=feature" as "image" with image data:
      | width | height | format |
      | 1024  | 512    | png    |
    Then there should be a 200 response from the "image" request that contains:
      | _id       | name         | usage   | path                                                   | size  |
      | OBJECT_ID | test-one.png | feature | {{ subscriptions[1]._id }}/feature/{{ image._id }}.jpg | 49394 |

  Scenario: Sending a valid request to create a "promotion" image will resize and save the image
    Given I am logged in with the "images-create-one@venzra-test.io" admin account
    And there is a PUT consumer at "https://s3.eu-west-1.amazonaws.com" that will return status 200
    When I make a binary data POST request to the API endpoint "/admin/images?name=test-two.png&usage=promotion" as "image" with image data:
      | width | height | format |
      | 512   | 512    | png    |
    Then there should be a 200 response from the "image" request that contains:
      | _id       | name         | usage     | path                                                     | size  |
      | OBJECT_ID | test-two.png | promotion | {{ subscriptions[1]._id }}/promotion/{{ image._id }}.jpg | 32887 |

  Scenario: Sending a valid request to create a "logo" image will resize and save the image
    Given I am logged in with the "images-create-one@venzra-test.io" admin account
    And there is a PUT consumer at "https://s3.eu-west-1.amazonaws.com" that will return status 200
    When I make a binary data POST request to the API endpoint "/admin/images?name=test-three.png&usage=logo" as "image" with image data:
      | width | height | format |
      | 512   | 512    | png    |
    Then there should be a 200 response from the "image" request that contains:
      | _id       | name           | usage | path                                                | size  |
      | OBJECT_ID | test-three.png | logo  | {{ subscriptions[1]._id }}/logo/{{ image._id }}.png | 30820 |

  Scenario: Sending a valid request to create a "icon" image will resize and save the image
    Given I am logged in with the "images-create-one@venzra-test.io" admin account
    And there is a PUT consumer at "https://s3.eu-west-1.amazonaws.com" that will return status 200
    When I make a binary data POST request to the API endpoint "/admin/images?name=test-four.png&usage=icon" as "image" with image data:
      | width | height | format |
      | 512   | 512    | png    |
    Then there should be a 200 response from the "image" request that contains:
      | _id       | name          | usage | path                                                | size  |
      | OBJECT_ID | test-four.png | icon  | {{ subscriptions[1]._id }}/icon/{{ image._id }}.png | 97340 |
