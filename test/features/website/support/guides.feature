@Website @Guides @GuidesRetrieve
Feature: Parse and display documentation and guide content held in markdown

  Scenario: Retrieve a documentation page
    When I make a GET request to the API endpoint "/website/support/guides/test/not-found" as "documentation"
    Then the status returned from the "documentation" request should be a 404 error

  Scenario: Retrieve a documentation page
    When I make a GET request to the API endpoint "/website/support/guides/getting-started/start-selling-online" as "documentation"
    Then there should be a 200 response from the "documentation" request that contains:
      | title                | content |
      | Start selling online | STRING  |
