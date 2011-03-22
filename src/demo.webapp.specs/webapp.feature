Feature: Addition
	In order to avoid silly mistakes
	As a math idiot
	I want to be told the sum of two numbers

Scenario: Navigation to home page
   When I navigate to home
   Then I should be on the home page
   Then I should see the text equal to "validatestring"