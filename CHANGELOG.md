# Changelog for the JSON Rails Logger gem


## 0.3.1 - 2021-07-20 (Bogdan)

- Updated dependencies

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

- This is an initial release, contains a simple JSON Rails Logger
  with some customisation applied to it
