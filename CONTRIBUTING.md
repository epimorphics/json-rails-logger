# Contributing to json-rails-logger

This guide covers development workflow for the json-rails-logger gem.

## Getting Started

After cloning the repository:

### Install Dependencies

```sh
make assets
```

This installs all required gems and dependencies.

### GitHub Package Registry Authentication

This gem is published to the Epimorphics GitHub Package Registry. This allows us
to publish and use Rubygems that we create in our own apps without publishing
via the public `rubygems.org` or wiring in direct references to GitHub repos in
our `Gemfile`s.

Access to the GitHub package registry is authorised via a _personal access
token_ (PAT), which is usually stored in `.github-token` in the project root
directory. Bundler needs to be configured to use the PAT when fetching gems from
the Epimorphics package registry.

#### For Users (Fetching the Gem)

To use this gem in your Rails application, you'll need to authenticate Bundler:

```sh
bundle config set --global https://rubygems.pkg.github.com/epimorphics USERNAME:TOKEN
```

Replace `USERNAME` with your GitHub username and `TOKEN` with your personal
access token.

#### For Developers (Working on the Gem)

By convention, there is a convenient `Makefile` target to help developers store
the PAT and authorise Bundler:

```sh
make auth
```

When run for the first time, this will prompt for your PAT.[^‡]

## Development Workflow

### `Makefile` Commands

The project includes a `Makefile` with other common development tasks:

- `make build` — Check that the gem builds correctly
- `make auth` — Create GitHub and Bundler authorisations
- `make test` — Run the test suite
- `make lint` — Run Rubocop linting
- `make check` — Run both linting and tests
- `make doc` — Generate YARD documentation
- `make publish` — Publish the gem to GitHub package registry

## API Documentation

The gem includes comprehensive YARD documentation on all public methods:

- **In your IDE**: Hover over `Logger.new` or `JsonFormatter.call` to see
  parameter types and usage examples
- **As HTML docs**: Run `make doc` to generate human-readable API reference in
  `doc/index.html`

The generated documentation includes method signatures with parameter types,
return value specifications, usage examples, and cross-references to related
Rails and Ruby standard library components. Each public method is annotated with
practical examples showing common configuration patterns and integration
scenarios.

## Publishing a New Version

To publish a new version of the gem after a bugfix or feature addition:

1. Ensure the version in `lib/json_rails_logger/version.rb` has been updated to
   reflect the correct semver representing the change
2. Update the `CHANGELOG.md` to document the new change
3. `git tag` the new state with a tag that matches the new version
4. Push the new tagged release to GitHub
5. Run `make publish` to push the new gem to the GitHub package registry

Pushing a tagged version will automatically trigger the publish gem workflow,
which should result in the gem appearing on the [list of
releases](https://github.com/epimorphics/json-rails-logger/releases).

[^‡]: See [notes on the
Epimorphics internal
wiki](https://github.com/epimorphics/internal/wiki/Ansible-CICD#creating-a-pat-for-gpr-access)
about creating a PAT.
