@Admin @Locations @LocationsSearch
Feature: Searching of available locations options

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName                    | status |
      | Admin Locations Search One   | ACTIVE |
      | Admin Locations Search Two   | ACTIVE |
      | Admin Locations Search Three | ACTIVE |
    And there are the following "accounts" records in the database
      | identity                              | password | status | subscription               |
      | locations-search-one@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[1]._id }} |
      | locations-search-two@venzra-test.io   | PASSWORD | ACTIVE | {{ subscriptions[2]._id }} |
      | locations-search-three@venzra-test.io | PASSWORD | ACTIVE | {{ subscriptions[3]._id }} |
    And there are the following "images" records in the database
      | subscription               | name                    | usage   | size |
      | {{ subscriptions[1]._id }} | LocationsSearch Image A | feature | 1024 |
    And there are the following "locations" records in the database
      | displayName          | description        | address                                                                                                                | featureImage        | usage    | subscription               |
      | Locations Search AAA | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | BUSINESS | {{ subscriptions[1]._id }} |
      | Locations Search AA  | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | STORE    | {{ subscriptions[1]._id }} |
      | Locations Search A   | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | BUSINESS | {{ subscriptions[1]._id }} |
      | Locations Search B   | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | BUSINESS | {{ subscriptions[1]._id }} |
      | Locations Search C   | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | STORE    | {{ subscriptions[1]._id }} |
      | Locations Search D   | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | STORE    | {{ subscriptions[1]._id }} |
      | Locations Search A   | Automated location | { "addressee": "Location manager", "street": "Street", "county": "County", "postalCode": "po57 3ox", "country": "GB" } | {{ images[1]._id }} | BUSINESS | {{ subscriptions[2]._id }} |

  Scenario: Requesting a list of locations should return only records for that subscription
    Given I am logged in with the "locations-search-one@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/locations" as "location"
    Then there should be a 200 response from the "location" request that contains:
      | list     | total |
      | ARRAY[6] | 6     |
    And the response from the "location" request has a "list" that contains rows:
      | _id                    | displayName          | address | featureImage                                                                              | usage    | created   |
      | {{ locations[3]._id }} | Locations Search A   | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[1]._id }}.jpg | BUSINESS | DATE_TIME |
      | {{ locations[2]._id }} | Locations Search AA  | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[1]._id }}.jpg | STORE    | DATE_TIME |
      | {{ locations[1]._id }} | Locations Search AAA | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[1]._id }}.jpg | BUSINESS | DATE_TIME |
      | {{ locations[4]._id }} | Locations Search B   | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[1]._id }}.jpg | BUSINESS | DATE_TIME |
      | {{ locations[5]._id }} | Locations Search C   | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[1]._id }}.jpg | STORE    | DATE_TIME |
      | {{ locations[6]._id }} | Locations Search D   | OBJECT  | https://images.venzra-test.com/{{ subscriptions[1]._id }}/feature/{{ images[1]._id }}.jpg | STORE    | DATE_TIME |

  Scenario: Requesting a list of locations should be empty when there are none for that subscription
    Given I am logged in with the "locations-search-three@venzra-test.io" admin account
    When I make a GET request to the API endpoint "/admin/locations" as "location"
    Then there should be a 200 response from the "location" request that contains:
      | list     | total |
      | ARRAY[0] | 0     |
