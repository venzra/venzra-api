@Admin @Locations @LocationsCreate
Feature: Creation of a new location entry

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                  | status |
      | Admin Locations Create One | ACTIVE |
      | Admin Locations Create Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                            | password | status | subscription               |
      | locations-create-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | locations-create-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                      | usage   | size |
      | {{ subscriptions[1]._id }} | LocationsRetrieve Image A | feature | 1024 |

  Scenario: An empty request to create a locations record fails validation
    Given I am logged in with the "locations-create-one@venzra-test.io" admin account
    When I make an empty POST request to the API endpoint "/admin/locations" as "location"
    Then there should be a 400 error from the "location" request that contains:
      | message           | detail                                                                                        |
      | Validation failed | ["displayName required", "description required", "address required", "featureImage required"] |

  Scenario: A valid request to create a new locations record is successful with defaults entered when not set
    Given I am logged in with the "locations-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/locations" as "location" using:
      | displayName        | description        | address                                                                                                                | featureImage        |
      | Locations Create A | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} |
    Then there should be a 200 response from the "location" request that contains:
      | _id       | displayName        | description        | address | featureImage                                                                              | usage    | created   | updated   |
      | OBJECT_ID | Locations Create A | Automated location | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[1]._id }}.jpg | BUSINESS | DATE_TIME | DATE_TIME |

  Scenario: A valid request to create a new locations record is successful and optional fields accepted
    Given I am logged in with the "locations-create-one@venzra-test.io" admin account
    When I make a POST request to the API endpoint "/admin/locations" as "location" using:
      | displayName        | description        | address                                                                                                                | featureImage        | usage |
      | Locations Create A | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | store |
    Then there should be a 200 response from the "location" request that contains:
      | _id       | displayName        | description        | address | featureImage                                                                              | usage | created   | updated   |
      | OBJECT_ID | Locations Create A | Automated location | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[1]._id }}.jpg | STORE | DATE_TIME | DATE_TIME |
