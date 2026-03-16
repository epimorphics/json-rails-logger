# JSON log formatter for Rails

## Understanding json-rails-logger

The json-rails-logger gem transforms Rails application logging from traditional
plain-text format into structured JSON output. This standardisation is
particularly valuable in environments where multiple applications need to
produce logs in a consistent format, making it easier to aggregate, search, and
analyse logs across different services.

At its core, the gem replaces Rails' default logger formatter with one that
serialises log entries as JSON objects. Each log message becomes a structured
document with predictable fields like timestamp, severity level, HTTP method,
request path, and response status. This structured approach eliminates the need
for complex log parsing and makes the logs immediately queryable by log
aggregation tools like Elasticsearch, Splunk, or CloudWatch Logs Insights.

A key feature of this logger is its handling of request context. It
automatically captures and includes the request_id in every log entry during an
HTTP request's lifecycle. This correlation identifier becomes invaluable when
tracing a single user request through multiple log entries, background jobs, or
even across microservices. The gem achieves this through middleware that stores
the request ID in thread-local storage, making it available to the formatter
without requiring explicit parameter passing throughout the application code.

The design philosophy prioritises consistency across Epimorphics' application
portfolio. By ensuring all Rails applications output logs in the same JSON
structure, the organisation gains a unified logging interface that simplifies
operations, monitoring, and debugging across its entire infrastructure. This
consistency is particularly beneficial when correlating events across multiple
applications or when building dashboards that aggregate metrics from various
sources.

## Internal structure

This logger makes use of [lograge](https://github.com/roidrage/lograge) to
"attempt to tame Rails' default policy". However, we augment the JSON format
used by lograge to fit our local requirements, and ensure the HTTP request ID is
logged where available.

### Gem API Documentation

The gem includes comprehensive YARD documentation covering all public classes,
methods, and configuration options. Running `make doc` generates a complete HTML
reference that provides detailed insights into the gem's internal architecture
and public API surface. This documentation is particularly valuable when
customising the logger's behaviour, understanding its integration points with
Rails, or extending its functionality for specialised use cases.

The generated documentation includes method signatures with parameter types,
return value specifications, usage examples, and cross-references to related
Rails and Ruby standard library components. Each public method is annotated with
practical examples showing common configuration patterns and integration
scenarios. The documentation also covers thread-safety considerations,
middleware behaviour, and the gem's interaction with Lograge's internal
mechanisms.

To explore the full API reference, class hierarchies, and method documentation,
run `make doc` from the project root. This executes YARD to parse the source
code annotations and produce browsable HTML output in the `doc/` directory and
then opens `doc/index.html` in your browser. The generated docs are particularly
useful when integrating the gem into complex Rails applications or when
troubleshooting unexpected logging behaviour.

## Installation

This gem is published to the Epimorphics [GitHub Package
Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-rubygems-registry).
You'll need to authenticate Bundler with a personal access token (PAT) to fetch
the gem. See [GitHub Package Registry
Authentication](CONTRIBUTING.md#github-package-registry-authentication) in
CONTRIBUTING.md for setup instructions.

In your Rails app, add this to your `Gemfile`:

```ruby
source "https://rubygems.pkg.github.com/epimorphics" do
  gem 'json_rails_logger'
end
```

And this to your environment config (e.g. `config/environments/production.rb`):

```ruby
config.logger = JsonRailsLogger::Logger.new(STDOUT)
```

## How It Works

### Automatic Railtie Setup

When `json_rails_logger` is required in your Gemfile, a Rails Railtie[^1]
automatically initialises:

1. **Middleware insertion**: The `RequestIdMiddleware` is inserted into your
   middleware stack
   - Automatically reads the HTTP `X-Request-ID` header (production) or
     `action_dispatch.request_id` (development)
   - Stores the request ID in thread-local storage for access during request
     processing
   - Cleans up after each request to prevent data leaking in thread pools

2. **Lograge configuration**: If a `JsonRailsLogger::Logger` is configured,
   Lograge is also set up to:
   - Output all log lines in JSON format
   - Include request exceptions in the JSON payload
   - Disable Rails' default colourised logging

### If You Don't Configure JsonRailsLogger

If you add the gem to your Gemfile but **don't** configure it as your logger:

- **Middleware still runs** (minimal overhead: just thread storage
  assignment/cleanup)
- **Lograge remains unconfigured** (Rails uses default logging)
- **Request ID won't appear in logs** (middleware captures it, but not used
  without configured logger)
- **No breaking changes** (gem is safe to include without immediate
  configuration)

### Thread-Local Storage and Request IDs

The request ID is stored in `Thread.current[JsonRailsLogger::REQUEST_ID]` for
several reasons:

- **Thread isolation**: Each request thread has its own request ID; no
  cross-request pollution
- **Automatic cleanup**: The ensure block in the middleware guarantees cleanup
  even if exceptions occur
- **No context passing**: The formatter and other components can read the
  request ID without it being passed as a parameter

## Filtering Specific Keys from Logs

The json-rails-logger gem provides built-in support for filtering specific keys
from log output. This is particularly useful for suppressing verbose or
repetitive fields that clutter logs without adding diagnostic value, removing
confidential information such as passwords, API keys, and access tokens that
might be stored or transmitted outside secure boundaries, and for selective
debugging — by keeping filtered keys hidden in production whilst optionally
preserving them under a debug key for troubleshooting and auditing purposes.

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

# Option 3: Remove keys but preserve under :_filtered for debugging
config.logger = JsonRailsLogger::Logger.new(
  STDOUT,
  filtered_keys: ['password', 'api_key'],
  keep_filtered_keys: true
)
# Output: {"ts":"...","level":"INFO","message":"User logged in","_filtered":{"password":"secret123","api_key":"xyz789"}}
```

> [!IMPORTANT]
> **Key matching** is exact and case-sensitive. Both string and
> symbol keys are supported (`['password']` and `[:password]` are equivalent).
> The `_filtered` key only appears when `keep_filtered_keys: true` **and** at
> least one key was filtered.

## Severity Levels

Log severity is normalised according to the following mapping:

| Input | Output |
|---|---|
| `DEBUG`, `TRACE`, `0` | `DEBUG` |
| `INFO`, `1` | `INFO` |
| `WARN`, `2` | `WARN` |
| `ERROR`, `3` | `ERROR` |
| `FATAL`, `CRITICAL`, `4` | `FATAL` |
| anything else | `UNKNOWN` |

> [!NOTE]
> Prior to v3.0.0, `FATAL` was mapped to `ERROR`. From v3.0.0 onwards `FATAL`
> is preserved. If your log pipeline or alerting rules differentiate on
> severity, you may need to update those rules when upgrading.

## Upgrading from v2.x

| v2.x | v3.x |
|---|---|
| `JsonFormatter.new(include_ignored_keys: true)` | No direct equivalent — use `filtered_keys:` to suppress specific noisy fields |
| `JsonFormatter::REQUIRED_KEYS` | `JsonFormatter::EXPECTED_KEYS` |
| `JsonFormatter::IGNORED_KEYS` | Removed — keys are no longer partitioned into ignored/required buckets |
| `FATAL` severity → `"ERROR"` in output | `FATAL` severity → `"FATAL"` in output |

## Contributing

For information on setting up a development environment, running tests,
generating documentation, and publishing releases, see
[CONTRIBUTING.md](CONTRIBUTING.md)

[^1]: <https://guides.rubyonrails.org/plugins.html#using-the-railtie> "Rails
    Guides: Using the Railtie – A Railtie is a mechanism to hook into Rails'
    initialization process, allowing gems to run setup code automatically when
    Rails boots"
