.PHONY: all assets auth build check checks clean coverage docs forceclean gem help lint publish realclean rubocop tag tags test updates vars version

GEM_NAME?=json_rails_logger
OWNER?=epimorphics
COMMIT=$(shell git rev-parse --short HEAD)
VERSION?=$(shell /usr/bin/env ruby -e 'require "./lib/${GEM_NAME}/version" ; puts JsonRailsLogger::VERSION')
TAG?=${VERSION}-${COMMIT}
PAT?=$(shell read -p 'Github access token:' TOKEN; echo $$TOKEN)
BUNDLE?=bundle

AUTH=${HOME}/.gem/credentials
GEM=${GEM_NAME}-${VERSION}.gem
GPR=https://rubygems.pkg.github.com/${OWNER}
SPEC=${GEM_NAME}.gemspec

${AUTH}:
	@mkdir -p ${HOME}/.gem
	@echo '---' > ${AUTH}
	@echo ':github: Bearer ${PAT}' >> ${AUTH}
	@chmod 0600 ${AUTH}

# Build the gem package
${GEM}: ${SPEC} ./lib/${GEM_NAME}/version.rb
	gem build ${SPEC}

all: check ## Default target: run all checks

assets:
	@echo "Installing assets for ${GEM_NAME} gem..."
	@bundle install
	@echo "Assets for ${GEM_NAME} gem are up to date."

auth: ${AUTH} ## Set up authentication for GitHub and Bundler
	@echo "Authentication set up for GitHub and Bundler."

build: clean checks gem ## Verify and build the gem
	@echo "Build and verification complete."

check: checks ## Alias for checks target

checks: lint test ## Run all checks: linting and tests
	@echo "All checks passed."

clean: ## Remove generated files
	@echo "Cleaning up..."
	@bundle exec rake clean clobber
	@rm -rf coverage doc *.gem

coverage: ## Display test coverage report
	@open coverage/index.html
	@echo "Displaying test coverage report in browser..."

docs: ## Generate YARD documentation and open in browser
	@echo "Generating YARD documentation..."
	@${BUNDLE} exec yard doc
	@open doc/index.html

forceclean: realclean ## Remove all bundled files and reset Bundler
	@${BUNDLE} clean --force || :

gem: ${GEM} ## Build the gem package for release
	@echo ${GEM}

help: ## Display this message
	@echo "Available make targets:"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'
	@echo ""
	@make vars

lint: rubocop ## Run linting checks
	@echo "Linting complete."

publish: ${AUTH} ${GEM} ## Publish the gem to the GitHub Package Registry
	@echo "Publishing ${GEM} to GitHub Package Registry..."
	@gem push --key github \
		--host ${GPR} ${GEM}
	@echo "Done."

realclean: clean ## Remove all generated files and authentication
	@echo "Removing authentication..."
	@rm -f ${AUTH}

rubocop: ## Run RuboCop linting
	@echo "Running RuboCop linting..."
	@${BUNDLE} exec rubocop -a

tag: ## Display the current gem tag
	@echo ${TAG}

tags: ## Display version information for CI pipeline
	@echo name=${GEM_NAME}
	@echo owner=${OWNER}
	@echo version=${VERSION}

test: assets ## Run the test suite
	@echo "Running tests..."
	@${BUNDLE} exec rake test

updates: ## Check for outdated Ruby gems with Bundler
	@echo "Running bundle outdated to check Ruby gems..."
	@${BUNDLE} outdated --only-explicit || true

vars: ## Display current variable values
	@echo "COMMIT          = ${COMMIT}"
	@echo "GEM             = ${GEM}"
	@echo "GEM_NAME        = ${GEM_NAME}"
	@echo "GPR             = ${GPR}"
	@echo "OWNER           = ${OWNER}"
	@echo "SPEC            = ${SPEC}"
	@echo "TAG             = ${TAG}"
	@echo "VERSION         = ${VERSION}"

version: ## Display the gem version
	@echo ${VERSION}
