# Contributing to json-rails-logger

This guide covers development workflow for the json-rails-logger gem.

## Getting Started

After cloning the repository:

### Install Dependencies

```sh
make bundles
```

This installs all required gems via Bundler.

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

By convention, there is a convenient `Makefile` target to help developers
authenticate with the GitHub Package Registry. Running `make auth` will prompt
for your PAT and write it to `~/.gem/credentials`:[^‡]

```sh
make auth
```

The same mechanism is used by the CI publication workflow, where the PAT is
supplied automatically via `secrets.GITHUB_TOKEN`.

## Development Workflow

### `Makefile` Commands

The project includes a `Makefile` with common development tasks:

- `make auth` — Create GitHub and Bundler authorisations
- `make build` — Build the gem locally
- `make check` — Run both linting and tests
- `make docs` — Generate YARD documentation and open in browser
- `make gem` — Build the gem package for release
- `make lint` — Run Rubocop linting
- `make publish` — Build and publish the gem to the GitHub Package Registry
- `make tags` — Display version information for the CI pipeline
- `make test` — Run the test suite
- `make updates` — Check for outdated Ruby gems

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

Pushing a tagged version will automatically trigger the publish gem workflow,
which should result in the gem appearing on the [list of
releases](https://github.com/epimorphics/json-rails-logger/releases). If the
workflow does not trigger or needs to be run manually, `make publish` will build
and push the gem directly to the GitHub Package Registry.

[^‡]: See [notes on the Epimorphics internal wiki](https://github.com/epimorphics/internal/wiki/Ansible-CICD#creating-a-pat-for-gpr-access)
about creating a PAT.
