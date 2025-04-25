# Changelog for the JSON Rails Logger gem

## 2.0.5 - 2025-04

- (Jon) Added a new method `remove_unprintable_characters` to filter out
  unprintable and non-ASCII characters from log messages.
- (Jon) Updated the `call` method to include the new `remove_unprintable_characters`
  method, ensuring that log messages are cleaned before being logged.

## 2.0.4 - 2025-04

- (Jon) Extracted the optional messages and `request_time` formatting logic to
  improve readability and maintainability.
- (Jon) Added a new method `process_optional_messages` to handle the formatting
  of the optional messages.
- (Jon) Updated the `call` method to include the new `process_optional_messages`
  method, ensuring that the optional messages are processed correctly.
- (Jon) Separated the request time formatting into its own block to improve
  readability and maintainability.
- (Jon) Updated .rubocop.yml to ignore long comments to reduce noise in the CI/CD
  pipeline

## 2.0.3 - 2025-03

- (Jon) Enhance logging with request time formatting
  - Added conditional check for request time presence
  - Improved request time format to include seconds and milliseconds
  - Updated log message structure for clarity
- (Jon) Added pre-commit and pre-push hooks to the gem to ensure the code is
  linted and tested before being committed or pushed to the repository.
- (Jon) Added detailed logging for completed actions, including the action name,
  controller, and request time. Updated log level to 'DEBUG' for these messages
  if not already set.
- (Jon) Changed how new messages are merged into the payload by sorting them
  before excluding optional fields. This should help maintain a consistent order
  in the logged output.
- (Jon) Changed the message formatting to transform keys into symbols for better
  consistency and usability.
- (Jon) Updated logging level for Webpacker messages to DEBUG for additional
  filtering capability

## 2.0.2 - 2025-02

- (Jon) Added new required keys for logging: message, method, path, etc.
- (Jon) Moved some keys to optional and updated their handling.
- (Jon) Improved payload formatting based on log severity in development.
- (Jon) Introduced a new method for fetching request parameters.
- (Jon) Enhanced duration normalisation logic.

## 2.0.1 - 2024-12

- (Bogdan) Regenerated `Gemfile.lock`

## 2.0.0 - 2024-12

- (Jon) Updated the gemspec for the required ruby version to 3.0.0 to ensure the
  gem is up to date with the latest ruby version
- (Jon) Updated the gemspec to ensure the railties gem is locked to the 7.0
  rails version to avoid any potential issues with the gem being used
- (Jon) Updated the logging to include the `request_id` in the JSON output to
  ensure the values are always logged to the system tooling.

## 1.1.1 - 2024-10

- (Jon) Updated the exposed keys to allow more flexibility in the logging
- (Jon) Merged the two GitHub actions into one to reduce the number of actions
  required to maintain the gem, while introducing dependency on successful
  linting and tests before the gem is published

## 1.1.0 - 2024-10

- (Dan) Updates ruby to 2.7.8 and version cadence to 1.1.0

## 1.0.4-rc01 - 2023-08

- (Jon) Updated the GitHub action to reflect the revised company's gem
  publishing strategy
- (Jon) Removed the push trigger as gem creation needs to be a manual process
- (Jon) Reorganised and removed duplicated makefile targets
- (Jon) Introduces the use of the `${NAME}` variable to increase portability of
  the revised makefile approach

## 1.0.3 - 2023-06-23

- (Jon) For continued improvements to the logs, additional keys need to be added
  to parse the details
  - Also includes string downcasing to improve matching of request fields

## 1.0.2 - 2023-06-21

- (Jon) Renamed parameter to reduce chance of conflict with other gems or code
  that may use the same parameter name.

## 1.0.1 - 2023-06-07

- (Jon) Updated the logging to include additional properties to ensure the
  values are always logged to the system tooling.
- (Jon) Updated the logging to exclude the Rails internal properties to ensure
  the values are NOT logged to the system tooling.
- (Jon) Minor formatting updates to resolve or silence Rubocop warnings

## 1.0.0 - 2023-06-01

- (Jon) Updated the version for the gem to be 1.0.0 as the gem has been in use
  for a while and is stable.

## 0.3.6.0 - 2023-06-01

- (Jon) Now uses the `env['action_dispatch.request_id']` variable ONLY in the
development environment in order to mimic the `HTTP_X_REQUEST_ID` header as that
header doesn't exist when running rails server in the development environment.
- (Jon) Reports on `GET, POST, PUT, DELETE, PATCH` request methods instead of
only `GET`

## 0.3.5.5 - 2023-05-10

- (Jon) Reverted the `gemspec` file to ensure the gem accepts higher ruby
versions and allows it to work with current app integrations; e.g. regulated
products
- (Jon) Reverted the `unit_tests.yml` file to ensure the test accepts higher
ruby versions and allows it to work with current app integrations; e.g.
regulated products

## 0.3.5.4 - 2023-03-24

- (Jon) Removed the rails specific properties from the JSON output as they are
  not required by the logging monitors and consume more disk space than desired.
- (Jon) Reordered the Timestamp and Level properties to match the order of other
  logs on the Epimorphics system tooling.

## 0.3.5.3 - 2023-03-10

- (Jon) Added .ruby-version file to ensure the gem is locked to the specific
  2.6.6 ruby version to reduce any potential issues with current app
  integrations
- (Jon) Updated the gemspec to ensure the gem is locked to the same 2.6.6 ruby
  version to reduce any potential issues with current app integrations
- (Jon) Removed dependency version locks due to connected apps not supporting
  newer versions of gems being used.

## 0.3.5.2 - 2023-03-07

- (Jon) Updated the gemspec to ensure the dependency versions are locked to
  specific base versions to avoid any potential issues with the gem being used
- (Jon) Added specific versions to the gemspec dependencies to resolve
  open-ended dependency warnings when publishing the gem.

## 0.3.5.1 - 2023-01-16

- (Jon) With additional logging being passed into the logger from outside
  sources, i.e. rails, this refactor validates if the duration property exists,
  checks for a floating point, usually meaning milliseconds, multiplies it by
  1000 to convert to microseconds and then rounds the result down to 0 decimal
  points to log to the system tooling.
- (Jon) Additional tweaks for the `.gemspec` details to bring them inline with
  the current company format.
- (Jon) Updated gemfile.lock with latest version updates
- (Jon) Updated Github testing workflow to use the v3 checkout version
- (Jon) Refactored the version cadence creation to include a SUFFIX value if
  provided; otherwise no SUFFIX is included in the version number.

## 0.3.4 - 2022-02-07

- (Ian) Set the base logger class to `ActiveSupport::Logger` so that it plays
  better with Rails

## 0.3.3. - 2022-02-03

- (Ian) Add the `.silence()` method to the base logger

## 0.3.2 - 2022-02-02

- (Ian) Re-write the README

## 0.3.1 - 2021-07-20 (Bogdan)

- Updated dependencies
- Fixed rubocop warnings

## 0.3.0 - 2021-07-02

- (Ian) Fix for GH-25: required files were not listed in the gemspec

## 0.2.2 - 2021-03-02 (Bogdan)

- `timestamp` renamed to `ts` in returning JSON
- Date format for timestamp changed to `%Y-%m-%dT%H:%M:%S.%3NZ`
- `request_id` is no longer internally generated if the header is missing from
  the request, but the field will be missing from the returning JSON instead

## 0.2.1 - 2021-02-23 (Bogdan)

- Unit tests should now autorun on push and pull_request actions
- `x-request-id` renamed to `request_id` in code and returning JSON

## 0.2.0 - 2021-02-01 (Bogdan)

- Platform related fields are now grouped together inside the `rails` field
- Request ID is now present in every log message
- MIT license file added to the repo
- Added readme file with usage instructions

## 0.1.0 - 2021-01-26 (Bogdan)

- This is an initial release, contains a simple JSON Rails Logger with some
  customisation applied to it
