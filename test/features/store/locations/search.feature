@Store @Locations @LocationsSearch
Feature: Searching of available locations options

  @Seed
  Scenario: Setup test data seed for feature
    Given there are the following "subscriptions" records in the database
      | storeName              | status |
      | Locations Search One   | ACTIVE |
      | Locations Search Two   | ACTIVE |
      | Locations Search Three | ACTIVE |
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
    Given the request origin headers are set to "locations-search-one.venzra-test.io"
    When I make a GET request to the API endpoint "/store/locations" as "location"
    Then there should be a 200 response from the "location" request that contains:
      | list     | total |
      | ARRAY[6] | 6     |
    And the response from the "location" request has a "list" that contains rows:
      | _id                    | displayName          | address | featureImage          | usage    |
      | {{ locations[3]._id }} | Locations Search A   | OBJECT  | OBJECT[_id,name,path] | BUSINESS |
      | {{ locations[2]._id }} | Locations Search AA  | OBJECT  | OBJECT[_id,name,path] | STORE    |
      | {{ locations[1]._id }} | Locations Search AAA | OBJECT  | OBJECT[_id,name,path] | BUSINESS |
      | {{ locations[4]._id }} | Locations Search B   | OBJECT  | OBJECT[_id,name,path] | BUSINESS |
      | {{ locations[5]._id }} | Locations Search C   | OBJECT  | OBJECT[_id,name,path] | STORE    |
      | {{ locations[6]._id }} | Locations Search D   | OBJECT  | OBJECT[_id,name,path] | STORE    |

  Scenario: Requesting a list of locations should be empty when there are none for that subscription
    Given the request origin headers are set to "locations-search-three.venzra-test.io"
    When I make a GET request to the API endpoint "/store/locations" as "location"
    Then there should be a 200 response from the "location" request that contains:
      | list     | total |
      | ARRAY[0] | 0     |
