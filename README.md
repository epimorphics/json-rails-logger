# JSON logger for Rails

A custom rails logger that outputs JSON instead of raw text. The goal of this
gem is to output log messages from Rails applications in a JSON format that
is consistent with the other applications that Epimorphics supports. Doing so
makes the combined logs in ElasticSearch much more useful for diagnosis and
other system administration tasks.

A particular feature of this logger is to output the `request_id` from the
currently active HTTP request in every log.

This gem can be used with any Rails app using the installation steps below.

## Using with a Rails application

In your Rails app, add this to your `Gemfile`:

```ruby
source "https://rubygems.pkg.github.com/epimorphics" do
  gem 'json_rails_logger'
end
```

And this to your environment config (e.g. `config/environments/production.rb`):

```ruby
config.logger = JsonRailsLogger::Logger.new(STDOUT)`
```

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

After cloning the repo, first execute:\
`bundle install`

Rubocop should produce no warnings.

### Running the tests

Tests are located in the `./test/` folder.

To run the tests, use:\
`rake test`

### `Makefile`

There is a `Makefile` with some shared dev tasks, but this is
primarily used by the automated publishing workflow.

To check that the gem will build correctly: `make build`

To create the GitHub and Bundler authorisations: `make auth`

### Publishing a new version of the gem

To publish a new version of the gem after a bugfix or feature addition:

1. Ensure that the version in `lib/json_rails_logger/version.rb` has
   been updated to reflect the correct semver representing the change
2. Update the `CHANGELOG.md` to document the new change
3. `git tag` the new state with a tag that matches the new version
4. Push the new tagged release to GitHub

Pushing a tagged version will automatically trigger the publish gem
workflow, which should result in the gem appearing on the
[list of releases](https://github.com/epimorphics/json-rails-logger/releases)
