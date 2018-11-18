@Admin @Locations @LocationsUpdate
Feature: Update locations information for display and modification

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                  | status |
      | Admin Locations Update One | ACTIVE |
      | Admin Locations Update Two | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                            | password | status | subscription               |
      | locations-update-one@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | locations-update-two@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                    | usage   | size |
      | {{ subscriptions[1]._id }} | LocationsUpdate Image A | feature | 1024 |
      | {{ subscriptions[1]._id }} | LocationsUpdate Image B | feature | 1024 |
    And there are the following "locations" records in the database
      | displayName        | description        | address                                                                                                                | featureImage        | subscription               |
      | Locations Update A | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | {{ subscriptions[1]._id }} |
      | Locations Update B | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | {{ subscriptions[1]._id }} |
      | Locations Update C | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | {{ subscriptions[2]._id }} |

  Scenario: Sending an empty update request does not change any data
    Given I am logged in with the "locations-update-one@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/locations/{{ locations[1]._id }}" as "location"
    Then there should be a 200 response from the "location" request that contains:
      | _id       | displayName        | description        | address | featureImage                                                                              | usage    | created   | updated   |
      | OBJECT_ID | Locations Update A | Automated location | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[1]._id }}.jpg | BUSINESS | DATE_TIME | DATE_TIME |

  Scenario: Update of locations correctly sets the new locations information
    Given I am logged in with the "locations-update-one@venzra-test.io" admin account
    When I make a PATCH request to the API endpoint "/admin/locations/{{ locations[1]._id }}" as "location" using:
      | op      | path         | value                                                                                                                       |
      | replace | displayName  | Location updated                                                                                                            |
      | replace | description  | Updated description                                                                                                         |
      | replace | address      | { "addressee": "Regional director", "street": "P.O. Box", "county": "Province", "postalCode": "te37 3od", "country": "GB" } |
      | replace | featureImage | {{ images[2]._id }}                                                                                                         |
      | replace | usage        | store                                                                                                                       |
    Then there should be a 200 response from the "location" request that contains:
      | _id       | displayName      | description         | address | featureImage                                                                              | usage | created   | updated   |
      | OBJECT_ID | Location updated | Updated description | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[2]._id }}.jpg | STORE | DATE_TIME | DATE_TIME |
    And the response path "address" from the "location" request contains:
      | _id       | addressee         | street   | county   | postalCode | country |
      | OBJECT_ID | Regional director | P.O. Box | Province | TE373OD    | GB      |

  Scenario: It is not possible for a user of another subscription to alter a location that does not belong to them
    Given I am logged in with the "locations-update-two@venzra-test.io" admin account
    When I make an empty PATCH request to the API endpoint "/admin/locations/{{ locations[1]._id }}" as "location"
    Then the status returned from the "location" request should be a 404 error
