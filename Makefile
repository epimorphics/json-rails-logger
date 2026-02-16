.PHONY: all assets auth build bundles check checks clean coverage gem help lint publish realclean rubocop tags test update vars

NAME?=json_rails_logger
OWNER?=epimorphics
VERSION?=$(shell /usr/bin/env ruby -e 'require "./lib/${NAME}/version" ; puts JsonRailsLogger::VERSION')
PAT?=$(shell read -p 'Github access token:' TOKEN; echo $$TOKEN)
BUNDLE?=bundle

AUTH=${HOME}/.gem/credentials
GEM=${NAME}-${VERSION}.gem
GPR=https://rubygems.pkg.github.com/${OWNER}
SPEC=${NAME}.gemspec

${AUTH}:
	@mkdir -p ${HOME}/.gem
	@echo '---' > ${AUTH}
	@echo ':github: Bearer ${PAT}' >> ${AUTH}
	@chmod 0600 ${AUTH}

# Build the gem package
${GEM}: ${SPEC} ./lib/${NAME}/version.rb
	gem build ${SPEC}

all: publish ## Default target: publish the gem

assets: auth bundles ## Build assets for gem package
	@echo assets completed.

auth: ${AUTH} ## Set up authentication for package distribution
	@echo "Authentication set up for package distribution."

build: clean gem ## Build the gem package

bundles: ## Install gem dependencies via Bundler
	@echo "Installing gem dependencies via Bundler..."
	@${BUNDLE} install

check: checks ## Alias for `checks` target

checks: lint test ## Run all checks: linting and tests
	@echo "All checks passed."

clean: ## Clean up generated gem package
	@echo "Removing ${GEM} ..."
	@rm -rf ${GEM}

coverage: ## Display test coverage report
	@open coverage/index.html
	@echo "Displaying test coverage report in browser..."

gem: ${GEM} ## Build the gem package
	@echo ${GEM}

help: ## Display this message
	@echo "Available make targets:"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'
	@echo ""
ifdef AWS_PROFILE
	@echo "Environment variables (optional: all variables have defaults):"
	@make vars
else
	@echo "Warning: AWS_PROFILE environment variable is not set. AWS CLI commands may fail."
	@echo "Re-run with AWS_PROFILE set to see all variables"
endif

lint: rubocop ## Run linting checks
	@echo "All linting complete."

publish: ${AUTH} ${GEM} ## Publish the gem package to Epimorphics Package Registry
	@echo Publishing package ${NAME}:${VERSION} to ${OWNER} ...
	@gem push --key github --host ${GPR} ${GEM}
	@echo Done.

realclean: clean ## Remove authentication files
	@rm -rf ${AUTH}

rubocop: ## Run RuboCop linting
	@echo "Running RuboCop linting for ${GEM} ..."
# Auto-correct offenses safely where possible with the `-a` flag
	@${BUNDLE} exec rubocop -a

tags: ## Display version information
	@echo version=${VERSION}

test: ## Run tests
	@echo "Running tests..."
	@${BUNDLE} exec rake test

update: ## Review and update dependencies interactively
	@echo "Checking for outdated dependencies..."
	@if [ -f package.json ]; then \
		echo "Running yarn upgrade-interactive..."; \
		yarn upgrade-interactive; \
	fi
	@echo "Running bundle outdated to check Ruby gems..."
# Let bundler handle output; treat this as informational even if deps are outdated
	@${BUNDLE} outdated --only-explicit || true

vars: ## Display environment variables
	@echo "GEM"	= ${GEM}
	@echo "GPR"	= ${GPR}
	@echo "NAME = ${NAME}"
	@echo "OWNER = ${OWNER}"
	@echo "SPEC = ${SPEC}"
	@echo "VERSION = ${VERSION}"
