@Store @Images @ImagesRetrieve
Feature: Retrieval of images stored on S3

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | strapline                    |
      | Store Images Retrieve One | Automated subscription entry |
      | Store Images Retrieve Two | Automated subscription entry |
    And there are the following "images" records in the database
      | subscription               | name                   | usage | size |
      | {{ subscriptions[1]._id }} | ImagesRetrieve Image A | icon  | 128  |
      | {{ subscriptions[1]._id }} | ImagesRetrieve Image B | logo  | 256  |

  Scenario: Requesting an image that does not belong to the subscription
    Given I am logged in with the "images-retrieve-two@venzra-test.io" store account
    When I make a GET request to the API endpoint "/store/images/{{ images[1]._id }}" as "image"
    Then the status returned from the "image" request should be a 404 error

  Scenario: Requesting an invalid image reference
    Given the request origin headers are set to "store-images-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/images/fake-image" as "image"
    Then the status returned from the "image" request should be a 404 error

  Scenario: Requesting meta information about the image stored
    Given the request origin headers are set to "store-images-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/images/{{ images[1]._id }}" as "image"
    Then there should be a 200 response from the "image" request that contains:
      | _id                 | name                   | usage | path                                                                                     | size |
      | {{ images[1]._id }} | ImagesRetrieve Image A | icon  | https://images.venzra-test.com/{{ images[1].subscription }}/icon/{{ images[1]._id }}.png | 128  |
