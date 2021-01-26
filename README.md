# json-rails-logger
A custom rails logger that outputs JSON instead of raw text. As an extra the logger also saves the `request_id` for any log message, in the returned JSON object. The formatter has a couple of changes that are down to preference, but these don't affect the functionality in any way. This gem can be used with any Rails app using the installation steps below.

## Installation
In your Rails app, add this to your gemfile:\
`gem 'json_rails_logger', git: 'git@github.com:epimorphics/json-rails-logger.git'`

And this to your environment config:\
`config.logger = JsonRailsLogger::Logger.new(STDOUT)`

## Running the tests
Tests are located in the `./test/` folder.

After cloning the repo, first execute:\
`bundle install`

To run the tests, use:\
`rake test`