# Changelog for the JSON Rails Logger gem

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
