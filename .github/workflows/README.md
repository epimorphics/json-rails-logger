# GitHub Actions Workflows

This directory contains the GitHub Actions workflow definitions for the
`json_rails_logger` gem. These workflows automate code quality checks, testing,
and release processes.

## Workflows Overview

| Workflow | File | Trigger | Purpose |
| --- | --- | --- | --- |
| Unit Tests | `unit-tests.yml` | Push to main, pull request to main, manual, workflow call | Runs the test suite and linting checks |
| Rubocop | `rubocop.yml` | Push to main, pull request to main, manual, workflow call | Checks code style compliance |
| Release and Publish | `publish.yml` | Manual dispatch | Gates on lint and tests, then builds, releases, and publishes the gem |

---

## Unit Tests (`unit-tests.yml`)

**Triggers:**

- Automatically on push and pull request to `main`
- Manually via the Actions UI or API
- Called directly by `publish.yml` as a required quality gate

**Purpose:** Installs dependencies, then runs linting and the test suite via
`make checks` to ensure code changes do not break existing functionality or
introduce style violations.

### Steps

1. Checks out the repository code with full git history
2. Detects the required Ruby version from `.ruby-version`
3. Sets up the Ruby environment
4. Installs dependencies via `make assets`
5. Runs linting and tests via `make checks`

### Notes

- The `EPI_GPR_READ_ACCESS_TOKEN` secret is required when called as a reusable
  workflow, to authenticate with the Epimorphics GitHub Package Registry
- Push and pull request triggers are restricted to `main` to prevent duplicate
  runs when a PR is open

---

## Rubocop Compliance (`rubocop.yml`)

**Triggers:**

- Automatically on push and pull request to `main`
- Manually via the Actions UI or API
- Called directly by `publish.yml` as a required quality gate

**Purpose:** Enforces Ruby code style and linting standards using Rubocop to
maintain consistent code quality across the project.

### Steps

1. Checks out the repository code
2. Sets up the Ruby environment
3. Installs dependencies via `make assets`
4. Runs Rubocop with GitHub-formatted output

### Notes

- The workflow will fail if any Rubocop offences are detected
- Ensure code passes locally with `bundle exec rubocop` before pushing

---

## Release and Publish Gem (`publish.yml`)

**Trigger:** Manual dispatch only (via GitHub Actions UI or API).

**Purpose:** Runs Rubocop compliance and the unit test suite as parallel quality
gates, then creates a GitHub release and publishes the gem to the GitHub Package
Registry. Publishing is restricted to the `main` branch; dispatching from
another branch runs the gates without releasing.

### Jobs

**`verify-rubocop`** — Calls `rubocop.yml` as a reusable workflow. The publish
job will not proceed unless this completes successfully.

**`verify-unit-tests`** — Calls `unit-tests.yml` as a reusable workflow. The
publish job will not proceed unless this completes successfully.

**`publish`** — Calls the shared
[`epimorphics/github-workflows`](https://github.com/epimorphics/github-workflows)
reusable workflow. Restricted to `main`; skipped silently on all other branches.

### Publish steps (via shared workflow)

1. Checks out the repository with full git history
2. Detects the required Ruby version from `.ruby-version`
3. Sets up the Ruby environment
4. Extracts gem name, owner, and version via `make tags`
5. Builds the gem package via `make gem`
6. Creates a GitHub release with auto-generated release notes
7. Publishes the gem to the GitHub Package Registry via `make publish`

### Prerequisites

- Update the version in `lib/json_rails_logger/version.rb`
- Update `CHANGELOG.md` with release notes
- Ensure the commit to release from is on `main`

### How to Trigger

1. Navigate to the **Actions** tab in GitHub
2. Select **Release and Publish Gem** from the workflow list
3. Click **Run workflow**
4. Select the branch (publishing will only proceed if `main` is selected)
5. Click the green **Run workflow** button

### Outputs

- A new GitHub release tagged with the version number
- The `.gem` file attached to the release
- The gem published to the GitHub Package Registry

---

## Troubleshooting

### Tests Failing

- Ensure all dependencies are installed: `make assets`
- Check that the Ruby version matches `.ruby-version`
- Verify your PAT is configured for the Epimorphics GitHub Package Registry

### Rubocop Failing

- Run `bundle exec rubocop -a` to auto-correct safe offences
- Review the Rubocop output for specific violations

### Publish Workflow Failing

- Verify the version number is correctly set in `version.rb`
- Confirm the workflow was dispatched from `main`
- Check that no release already exists for the target version

---

## Local Development

For setup instructions, available `make` targets, and guidance on running tests
and linting locally, see [CONTRIBUTING.md](../../CONTRIBUTING.md).
