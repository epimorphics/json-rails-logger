# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [3.0.1] - 2026-04

### Fixed

- `request_time` is now emitted as a floating-point number (e.g. `1.094`) rather
  than a string (e.g. `"1.094"`), correcting a type inconsistency with the
  [Epimorphics Logging Standard](https://github.com/epimorphics/internal/wiki/Logging-Standard#additional-fields)
  which requires consistent numeric types for fields consumed by the logging
  stack.
- `message` is now omitted from log output entirely when no message value is
  present (e.g. structured-only Faraday client log entries), rather than being
  emitted as `null`. The logging standard requires fields to appear only when
  pertinent.

### Changed

- Makefile rewritten to reflect gem development workflow. Application-specific
  targets have been removed, missing targets (`gem`, `tags`, `docs`) added, and
  broken targets (`VERSION` path, `test`, `lint`, `publish`) corrected. The
  `gem` and `tags` targets are required by the CI publication workflow. All
  targets are alphabetically ordered.
- CONTRIBUTING.md updated to correct the setup command, reflect current
  Makefile targets, fix a stale authentication reference, and clarify the
  publication process.
- README.md restructured for faster reference during incidents, with output format
  and severity levels moved to the top. Real log examples, a common fields
  table, Puma configuration guidance, and version requirements added. The
  upgrading section correctly distinguishes v2.x from v2.3.0 changes.

## [3.0.0] - 2026-03

### Added

- Introduced dedicated formatting components: `MessageParser`,
  `MessageValidator`, `PayloadBuilder`, `RequestContext`, and `MessageComposer`.
- Implemented `filtered_keys` configuration to suppress specified keys from log
  output, and `keep_filtered_keys` to optionally retain suppressed values under
  `:_filtered` for diagnostic purposes.
  [#67](https://github.com/epimorphics/json-rails-logger/issues/67)
- Expanded formatter tests to cover severity normalisation, nil/malformed
  inputs, payload key ordering, and filtered key output placement.
- Included README upgrade guidance for consumers moving from v2.x to v3.x.

### Changed

- Refactored `JsonFormatter` to delegate formatting concerns to dedicated
  internal components.
- Updated severity normalisation so `FATAL` is preserved as `FATAL` and unknown
  values map to `UNKNOWN`.
- Reordered payload output so `ts`, `level`, and `message` are emitted first,
  and `:_filtered` is emitted last when present.
- Clarified logger and README documentation for formatter override behaviour and
  filtering configuration.

### Removed

- Removed `JsonFormatter::IGNORED_KEYS`.
- Retired previous ignored-key behaviour based on `include_ignored_keys`.

### Fixed

- Corrected request-time normalisation when duration or request-time values are
  nil or floats.
- Improved consistency of string/raw message parsing and sanitisation.

## [2.3.0] - 2026-02

### Added

- Made ignored fields configurable via `include_ignored_keys` initialiser
  parameter (defaults to `false` for backward compatibility).
- Implemented test coverage for ignored field inclusion modes (enabled/disabled
  configurations).
- Included test coverage reporting via SimpleCov.
- Added YARD documentation workflow with versioned outputs for improved release
  documentation.

### Changed

- Restructured JSON payload assembly to prioritise `ts`, `level`, and `message`
  fields at output.
- Simplified request completion messages to use single-line format with
  controller and action.
- Included log level in required log fields for consistent output.
- Updated request completion messages to include path, controller, and action.
- Simplified payload assembly to build from timestamp before merging fields.
- Updated framework and libraries via Railties update to 8.1.2 for
  compatibility.

### Fixed

- Fixed log level assignment to handle nil severity values gracefully without
  truncation errors.
- Trimmed extraneous whitespace from log level field with `squish`.
- Fixed request params being logged under the wrong key.
- Fixed request time formatting when milliseconds are provided as floats.
- Fixed query string handling when it is missing to avoid errors.

## [2.2.0] - 2025-09

### Added

- Added debug log statements for easier tracing.

### Changed

- Enhanced status and request type parsing logic.
- Refined message formatting to skip when optional data is missing.
- Added checks for log message prefixes to improve parsing.

## [2.1.0] - 2025-09

### Added

- Added new development gems for rake task linting and debugging.

### Changed

- Updated Ruby version compatibility to latest compatible releases.
- Updated dependency versions to latest compatible releases.
- Improved logging formatter logic for clearer and safer output.
- Refined log message format for action/controller outputs.
- Updated code comments for accuracy and clarity.

## [2.0.6] - 2025-05

### Added

- Added graceful nil message handling.
- Added progname to logged messages.

### Changed

- Improved severity level processing with mapping for numeric and string levels.
- Enhanced program name processing with trailing space removal.
- Standardised Webpacker log level to DEBUG for filtering.
- Refined timestamp variable naming for clarity.
- Improved log level formatting with left-justification in payload.
- Suppressed colourised output and original logs.
- Added documentation for custom JSON formatter configuration.

## [2.0.5] - 2025-04

### Added

- Added `remove_unprintable_characters` method to filter unprintable and
  non-ASCII characters.

### Changed

- Updated the `call` method to filter log messages before logging.

## [2.0.4] - 2025-04

### Changed

- Extracted optional messages and request_time formatting logic into dedicated
  methods for improved readability.
- Separated request time formatting logic to improve maintainability.
- Updated rubocop configuration to ignore long comments.

## [2.0.3] - 2025-03

### Added

- Added pre-commit and pre-push hooks to enforce linting and testing.

### Changed

- Enhanced request time formatting with conditional checks and
  seconds/milliseconds display.
- Improved action logging to include action name, controller, and request time.
- Updated log level in certain messages to DEBUG for better filtering.
- Refined payload merging to sort messages before excluding optional fields.
- Changed message key transformation to symbols for consistency.

## [2.0.2] - 2025-02

### Added

- Added new required keys for logging (message, method, path, etc.).
- Introduced request parameters fetching method.

### Changed

- Reorganised key categories to distinguish required from optional keys.
- Improved payload formatting based on log severity in development.
- Enhanced duration normalisation logic.

## [2.0.1] - 2024-12

### Changed

- Regenerated Gemfile.lock with latest dependency versions.

## [2.0.0] - 2024-12

### Added

- Added request_id to JSON output for integration with system tooling.

### Changed

- Updated required Ruby version to 3.0.0 in gemspec.
- Updated railties dependency to Rails 7.0 for compatibility.

---

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
