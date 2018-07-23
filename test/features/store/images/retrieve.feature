@Store @Images @ImagesRetrieve
Feature: Retrieval of images stored on S3

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName           | strapline                    |
      | Images Retrieve One | Automated subscription entry |
      | Images Retrieve Two | Automated subscription entry |
    And there are the following "images" records in the database
      | subscription               | name                   | usage | size |
      | {{ subscriptions[1]._id }} | ImagesRetrieve Image A | icon  | 128  |
      | {{ subscriptions[1]._id }} | ImagesRetrieve Image B | logo  | 256  |

  Scenario: Requesting an image that does not exist on S3
    Given the request origin headers are set to "images-retrieve-one.venzra-test.io"
    And there is a HEAD consumer at "https://s3.eu-west-1.amazonaws.com/images.venzra-test.com" for "/{{ subscriptions[1]._id }}/icon/{{ images[1]._id }}" that will return status 404
    When I make a GET request to the API endpoint "/store/images/{{ images[1]._id }}" as "image" with "application/octet-steam" content type
    Then the status returned from the "image" request should be a 404 error

  Scenario: Requesting an image that is an icon of type PNG
    Given the request origin headers are set to "images-retrieve-one.venzra-test.io"
    And there is a HEAD consumer at "https://s3.eu-west-1.amazonaws.com/images.venzra-test.com" for "/{{ subscriptions[1]._id }}/icon/{{ images[1]._id }}" that will return "images/meta-png.json" with status 200
    And there is a GET consumer at "https://s3.eu-west-1.amazonaws.com/images.venzra-test.com" for "/{{ subscriptions[1]._id }}/icon/{{ images[1]._id }}" that will return "images/400x100.png" with status 200
    When I make a GET request to the API endpoint "/store/images/{{ images[1]._id }}" as "image" with "application/octet-steam" content type
    Then there should be a 200 response from the "image" request with an "image/png" binary containing:
      | width | height | format |
      | 400   | 100    | png    |

  Scenario: Requesting an image that is a logo of type JPEG
    Given the request origin headers are set to "images-retrieve-one.venzra-test.io"
    And there is a HEAD consumer at "https://s3.eu-west-1.amazonaws.com/images.venzra-test.com" for "/{{ subscriptions[1]._id }}/icon/{{ images[1]._id }}" that will return "images/meta-jpeg.json" with status 200
    And there is a GET consumer at "https://s3.eu-west-1.amazonaws.com/images.venzra-test.com" for "/{{ subscriptions[1]._id }}/icon/{{ images[1]._id }}" that will return "images/400x100.jpg" with status 200
    When I make a GET request to the API endpoint "/store/images/{{ images[1]._id }}" as "image" with "application/octet-steam" content type
    Then there should be a 200 response from the "image" request with an "image/jpeg" binary containing:
      | width | height | format |
      | 400   | 100    | jpeg   |

  Scenario: Requesting an invalid image reference
    Given the request origin headers are set to "images-retrieve-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/images/fake-image" as "image" with "application/octet-steam" content type
    Then the status returned from the "image" request should be a 404 error
