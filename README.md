# JSON log formatter for Rails

## 2am incident quick start

If alarms are firing and you need to confirm whether logger behaviour is a
contributor, use this path first:

Makefile path:

```sh
make assets
make lint
make test
```

Direct targeted tests:

```sh
bundle exec rake test TEST=test/formatter_test.rb
bundle exec rake test TEST=test/middleware_test.rb
```

### Known-good lifecycle sample

Use this as a quick visual check for expected request progression under one
`request_id`:

```json
{"ts":"1970-01-01T00:00:33.722Z","level":"INFO","message":"Received request for /","method":"GET","path":"/","request_id":"c5ff5ecb-0242-4359-88cb-652930d880f6","request_status":"received"}
{"ts":"1970-01-01T00:00:34.884Z","level":"INFO","message":"Received response from API with 183 items, time taken: 1094 ms","method":"GET","path":"/catalog/data/dataset?_view=compact","query_string":"_view=compact","request_id":"c5ff5ecb-0242-4359-88cb-652930d880f6","request_status":"processing","request_time":1.094,"returned_rows":183,"status":200}
{"ts":"1970-01-01T00:00:35.555Z","level":"INFO","message":"Datasets index request complete, time taken: 1779 ms","method":"GET","path":"/","request_id":"c5ff5ecb-0242-4359-88cb-652930d880f6","request_status":"completed","request_time":1.779,"status":200}
```

Expected outcome:

- Linting exits cleanly
- Test suite passes
- Formatter tests confirm expected JSON structure and severity mapping
- Middleware tests confirm request ID propagation and cleanup

If these checks pass, the logger gem is less likely to be the primary source of
an incident, and focus should move to consuming application logic, upstream
services, or log transport and alerting configuration.

## Is this gem likely the source?

Likely:

- Log lines are no longer valid single-line JSON
- Expected fields such as `ts`, `level`, or `request_id` are missing
- Severity values differ from documented mapping and alert thresholds
- Request lifecycle correlation is broken for a single `request_id`

Less likely:

- Upstream service latency or 5xx rates changed, but log structure is stable
- Consumer application business logic is failing with correctly formatted logs
- Log shipper or indexing pipeline is down or dropping messages

## Local verification path

### Requirements

- Ruby `>= 3.0.0`
- Rails `>= 6.0` (via `railties`)
- Bundler authenticated to the Epimorphics GitHub Package Registry

See [GitHub Package Registry
Authentication](CONTRIBUTING.md#github-package-registry-authentication) in
CONTRIBUTING.md.

### Verify in 5 minutes

```sh
make assets
make check
```

`make check` runs both linting and tests.

### Targeted behaviour checks

```sh
bundle exec rake test TEST=test/formatter_test.rb
bundle exec rake test TEST=test/logger_test.rb
bundle exec rake test TEST=test/middleware_test.rb
```

These tests give fast confidence in the core behaviours most likely to trigger
logging alarms.

### Consumer app smoke check

In a Rails host application using this gem, issue one request and verify logs
contain valid JSON entries with stable `request_id`, expected `request_status`
transitions, and mapped `level` values.

## Fast triage checklist

1. Confirm the deployed logger gem version changed
2. Validate consuming app still initialises `JsonRailsLogger::Logger`
3. Confirm expected severity mapping still matches alerting rules
4. Check `filtered_keys` changes did not remove alert-critical fields
5. Verify Puma log formatting if startup logs must remain JSON

## Understanding json-rails-logger

The json-rails-logger gem replaces Rails' default plain-text log formatter with
one that serialises every log entry as a structured JSON object. Each entry
carries predictable fields such as timestamp, severity, HTTP method, request
path, and response status, making logs queryable by aggregation tools such as
Elasticsearch or Kibana without custom parsing.

The gem is designed for consistency across Epimorphics applications. Rails
applications using it produce logs in the same JSON structure with the same
field names, which simplifies operations, monitoring, and cross-service
debugging.

> [!TIP]
> Use the outline icon (☰) at the top right of this page to jump directly to
> any section.

## Output format

Every log entry is a single-line JSON object. Fields are ordered with `ts`,
`level`, and `message` first, followed by remaining fields alphabetically.
Fields are only present when they carry a value. Absent fields are omitted
rather than emitted as `null`.

### Request lifecycle

Each incoming HTTP request produces a sequence of log entries sharing a
`request_id`. The `request_status` field tracks progress through the lifecycle.

```json
{"ts":"1970-01-01T00:00:33.722Z","level":"INFO","message":"Received request for /","method":"GET","path":"/","request_id":"c5ff5ecb-0242-4359-88cb-652930d880f6","request_status":"received"}
```

```json
{"ts":"1970-01-01T00:00:34.884Z","level":"INFO","message":"Received response from API with 183 items, time taken: 1094 ms","method":"GET","path":"/catalog/data/dataset?_view=compact","query_string":"_view=compact","request_id":"c5ff5ecb-0242-4359-88cb-652930d880f6","request_status":"processing","request_time":1.094,"returned_rows":183,"status":200}
```

```json
{"ts":"1970-01-01T00:00:35.555Z","level":"INFO","message":"Datasets index request complete, time taken: 1779 ms","method":"GET","path":"/","request_id":"c5ff5ecb-0242-4359-88cb-652930d880f6","request_status":"completed","request_time":1.779,"status":200}
```

The `request_id` is the correlation thread across all entries for a single
request, making it straightforward to trace a complete request lifecycle in a
log aggregation tool. `query_string` appears only when present.

### Common fields

The following fields appear consistently across Epimorphics applications.
Consuming applications may include additional fields alongside these.

| Field | Type | Description |
| --- | --- | --- |
| `ts` | string | ISO 8601 timestamp with millisecond precision, UTC |
| `level` | string | Severity, see [Severity Levels](#severity-levels) |
| `message` | string | Human-readable description of the event |
| `method` | string | HTTP method (`GET`, `POST`, etc.) |
| `path` | string | Request path for inbound entries, full upstream URL for outbound entries |
| `query_string` | string | Query string, when present |
| `request_id` | string | Correlation ID from the `X-Request-ID` header |
| `request_status` | string | `received`, `processing`, `completed`, or `error` |
| `request_time` | float | Time taken in seconds (for example `1.094`) |
| `returned_rows` | integer | Number of rows or items returned |
| `status` | integer | HTTP response status code |

> [!NOTE]
> For outbound API requests logged via Faraday or similar HTTP clients,
> `path` carries the full upstream URL including host and scheme (for example
> `https://api.example.com/data/items`), rather than a relative path.

### Structured-only entries

When an application logs purely structured data with no human-readable message,
as Faraday client logging typically does, the `message` field is omitted rather
than emitted as `null`.

```json
{"ts":"1970-01-01T00:00:33.787Z","level":"DEBUG","method":"GET","path":"https://api.example.com/catalog/data/dataset?_view=compact","request_id":"c5ff5ecb-0242-4359-88cb-652930d880f6"}
```

This means log queries or alerting rules that filter on `message` should
account for entries where the field is absent.

## Severity levels

Log severity is normalised according to the following mapping.

| Input | Output |
| --- | --- |
| `DEBUG`, `TRACE`, `0` | `DEBUG` |
| `INFO`, `1` | `INFO` |
| `WARN`, `2` | `WARN` |
| `ERROR`, `3` | `ERROR` |
| `FATAL`, `CRITICAL`, `4` | `FATAL` |
| anything else | `UNKNOWN` |

> [!NOTE]
> Prior to v3.0.0, `FATAL` was mapped to `ERROR`. From v3.0.0 onwards `FATAL`
> is preserved. If alerting rules differentiate on severity, those rules may
> need to be updated when upgrading.

## How it works

### Automatic Railtie setup

When `json_rails_logger` is required in your Gemfile, a Rails Railtie[^1]
automatically initialises:

1. **Middleware insertion**: The `RequestIdMiddleware` is inserted into your
   middleware stack
   - Reads the HTTP `X-Request-ID` header (production) or
     `action_dispatch.request_id` (development)
   - Stores the request ID in thread-local storage for request processing
   - Cleans up after each request to prevent data leaking in thread pools

2. **Lograge configuration**: If a `JsonRailsLogger::Logger` is configured,
   Lograge is also set up to:
   - Output all log lines in JSON format
   - Include request exceptions in the JSON payload
   - Disable Rails default colourised logging

> [!IMPORTANT]
> The gem's Railtie configures Lograge at load time, setting formatter,
> suppressing colourised output, and enabling exception payloads. If Lograge
> behaviour seems unexpected in an application, inspect this first.

### Thread-local storage and request IDs

The request ID is stored in `Thread.current[JsonRailsLogger::REQUEST_ID]` for
several reasons:

- **Thread isolation**: Each request thread has its own request ID
- **Automatic cleanup**: Middleware ensure block guarantees cleanup
- **No context passing**: Formatter and related components can read request ID
  without explicit parameter passing

## Puma log formatting

Rails startup and Puma server messages are emitted outside the Rails logger and
require separate configuration to appear as JSON. Add this to `config/puma.rb`:

```ruby
log_formatter do |str|
  {
    level: 'INFO',
    ts: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
    message: str.strip
  }.to_json
end
```

Without this, Puma startup lines are plain text and may be discarded by log
aggregation tools expecting well-formed JSON.

## Filtering specific keys from logs

The json-rails-logger gem provides support for filtering specific keys from log
output. This is useful for suppressing noisy fields, removing confidential
information, and preserving selected filtered values for controlled debugging.

### Configuration

Configure filtering when initialising the logger in your Rails environment
config:

```ruby
# config/environments/production.rb

# Option 1: No filtering (default)
config.logger = JsonRailsLogger::Logger.new(STDOUT)

# Option 2: Remove sensitive keys entirely
config.logger = JsonRailsLogger::Logger.new(
  STDOUT,
  filtered_keys: ['password', 'api_key', 'token']
)
# Output: {"ts":"...","level":"INFO","message":"User logged in"}

# Option 3: Remove keys and preserve under :_filtered for debugging
config.logger = JsonRailsLogger::Logger.new(
  STDOUT,
  filtered_keys: ['password', 'api_key'],
  keep_filtered_keys: true
)
# Output: {"ts":"...","level":"INFO","message":"User logged in","_filtered":{"password":"secret123","api_key":"xyz789"}}
```

> [!IMPORTANT]
> Key matching is exact and case-sensitive. Both string and symbol keys are
> supported (`['password']` and `[:password]` are equivalent). The `_filtered`
> key only appears when `keep_filtered_keys: true` and at least one key was
> filtered.

## Installation

This gem is published to the Epimorphics [GitHub Package
Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-rubygems-registry).

### Setup

In your Rails app, add this to your `Gemfile`:

```ruby
source "https://rubygems.pkg.github.com/epimorphics" do
  gem 'json_rails_logger'
end
```

And this to your environment config (for example
`config/environments/production.rb`):

```ruby
config.logger = JsonRailsLogger::Logger.new(STDOUT)
```

## Internal structure

This logger uses [lograge](https://github.com/roidrage/lograge) to replace
Rails default output and augment JSON formatting for Epimorphics requirements,
including request ID capture where available.

## Upgrading from v2.x

### All v2.x versions

| v2.x | v3.x |
| --- | --- |
| `JsonFormatter::REQUIRED_KEYS` | `JsonFormatter::EXPECTED_KEYS` |
| `JsonFormatter::IGNORED_KEYS` | Removed, no ignored/required partition |
| `FATAL` severity maps to `ERROR` | `FATAL` severity maps to `FATAL` |

### Additionally from v2.3.0

In v2.3.0, `include_ignored_keys: true` was introduced as an opt-in to include
fields suppressed by default (such as `action`, `controller`, or `user_agent`):

```ruby
config.logger = JsonRailsLogger::Logger.new(STDOUT, include_ignored_keys: true)
```

In v3.x this approach is inverted. Fields are included by default and
`filtered_keys:` is used to explicitly suppress specific ones:

```ruby
config.logger = JsonRailsLogger::Logger.new(
  STDOUT,
  filtered_keys: ['action', 'controller', 'user_agent']
)
```

See [Filtering Specific Keys from Logs](#filtering-specific-keys-from-logs) for
full configuration options.

## Contributing

For setup, development workflow, and release process, see
[CONTRIBUTING.md](CONTRIBUTING.md).

The gem includes YARD documentation on all public classes and methods. Run
`make docs` from the project root to generate a browsable HTML reference in the
`doc/` directory.

[^1]: <https://guides.rubyonrails.org/plugins.html#using-the-railtie> "Rails
    Guides: Using the Railtie, a Railtie is a mechanism to hook into Rails
    initialisation process, allowing gems to run setup code automatically when
    Rails boots"
