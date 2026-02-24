# JSON log formatter for Rails

A custom rails log formatter that outputs JSON instead of raw text. The goal of
this gem is to output log messages from Rails applications in a JSON format that
is consistent with the other applications that Epimorphics supports. Doing so
makes the combined logs more useful for diagnosis and other system
administration tasks.

A particular feature of this logger is to output the `request_id` from the
currently active HTTP request in every log.

This gem can be used with any Rails app using the installation steps below.

## Internal structure

This logger makes use of [lograge](https://github.com/roidrage/lograge) to
"attempt to tame Rails' default policy". However, we augment the JSON format
used by lograge to fit our local requirements, and ensure the HTTP request ID
is logged where available.

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

### Configuring Optional Fields

By default, optional fields (e.g. `user_agent`, `accept`, `controller`,
`action`) are excluded from JSON output. To include them, configure the
logger with the `include_optional` parameter:

```ruby
config.logger = JsonRailsLogger::Logger.new(STDOUT, include_optional: true)
```

This is useful during development or debugging when you want more detailed
request information.

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
