@Admin @Images @ImagesRetrieve
Feature: Retrieval of images stored on S3

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                 | strapline                    |
      | Admin Images Retrieve One | Automated subscription entry |
      | Admin Images Retrieve Two | Automated subscription entry |
    And there are the following "images" records in the database
      | subscription               | name                   | usage | size |
      | {{ subscriptions[1]._id }} | ImagesRetrieve Image A | icon  | 128  |
      | {{ subscriptions[1]._id }} | ImagesRetrieve Image B | logo  | 256  |
    And there are the following "accounts" records in the database
      | identity                           | password | status | subscription               |
      | images-retrieve-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | images-retrieve-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |

  Scenario: Requesting an image that does not belong to the subscription
    Given I am logged in with the "images-retrieve-two@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/images/{{ images[1]._id }}" as "image"
    Then the status returned from the "image" request should be a 404 error

  Scenario: Requesting meta information about the image stored
    Given I am logged in with the "images-retrieve-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/images/{{ images[1]._id }}" as "image"
    Then there should be a 200 response from the "image" request that contains:
      | _id                 | name                   | usage | path                                                      | size |
      | {{ images[1]._id }} | ImagesRetrieve Image A | icon  | {{ images[1].subscription }}/icon/{{ images[1]._id }}.png | 128  |
