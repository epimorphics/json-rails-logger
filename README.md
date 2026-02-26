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
used by lograge to fit our local requirements, and ensure the HTTP request ID
is logged where available.

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

## Using with a Rails application

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

To include fields that are ignored by default (such as `action`, `controller`,
or `user_agent`), set `include_ignored_keys: true` when configuring the logger
(e.g. in `config/environments/development.rb`):

```ruby
config.logger = JsonRailsLogger::Logger.new(STDOUT, include_ignored_keys: true)
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

## GitHub package registry

This gem is published via the Epimorphics instance of the
[GitHub Package Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-rubygems-registry).
This allows us to publish and use Rubygems that we create, in our own apps,
without having to pubish via the public `rubygems.org`, or wire-in direct
references to GitHub repos in our `Gemfile`s.

Access to the GihHub package registry is authorised via a _personal access
token_ (PAT), which is usually stored in `.github-token` in the project's
root directory. Bundler will need to configured to use the PAT when fetching
gems from the Epimorphics package registry. By convention, there should be
a convenient `Makefile` target to help developers to both store the PAT and
authorise Bundler:

```sh
make auth
```

When run for the first time, this will ask for your PAT. See
[notes on the internal wiki](https://github.com/epimorphics/internal/wiki/Ansible-CICD#creating-a-pat-for-gpr-access)
about creating a PAT.

See also notes on making a release of the gem, below.

## Developer notes

After cloning the repo, to install all dependecies, first execute

   make assets

### Linting the code

To check forrmatting and use, execute

   make lint

Rubocop should produce no warnings.

### Running the tests

Tests are located in the `./test/` folder.

To run the tests, use

   make test

#### One step check

You can also runs both linting and tests using

   make check

### `Makefile`

There is a `Makefile` with some shared dev tasks.

To check that the gem will build correctly: `make build`

To create the GitHub and Bundler authorisations: `make auth`

To publish the gem to the GitHub package registry: `make publish`

### API Documentation

The gem includes comprehensive YARD documentation on all public methods:

- **In your IDE**: Hover over `Logger.new` or `JsonFormatter.call` to see
  parameter types and usage examples
- **As HTML docs**: Run `make doc` to generate human-readable API reference in
  `doc/index.html`

This documentation includes parameter types, return values, example usage, and
cross-references to Rails and Ruby stdlib documentation.

### Publishing a new version of the gem

To publish a new version of the gem after a bugfix or feature addition:

1. Ensure that the version in `lib/json_rails_logger/version.rb` has
   been updated to reflect the correct semver representing the change
2. Update the `CHANGELOG.md` to document the new change
3. `git tag` the new state with a tag that matches the new version
4. Push the new tagged release to GitHub
5. Run `make publish` to push the new gem to the GitHub package registry.

Pushing a tagged version will automatically trigger the publish gem
workflow, which should result in the gem appearing on the
[list of releases](https://github.com/epimorphics/json-rails-logger/releases)

---

[^1]: <https://guides.rubyonrails.org/plugins.html#using-the-railtie> "Rails Guides: Using the Railtie – A Railtie is a mechanism to hook into Rails' initialization process, allowing gems to run setup code automatically when Rails boots"
