.PHONY: auth clean gem publish test

NAME?=$(shell ruby -e 'require "./lib/json_rails_logger/version" ; puts JsonRailsLogger::NAME')
OWNER?=$(shell ruby -e 'require "./lib/json_rails_logger/version" ; puts JsonRailsLogger::OWNER')
VERSION?=$(shell ruby -e 'require "./lib/json_rails_logger/version" ; puts JsonRailsLogger::VERSION')
PAT?=$(shell read -p 'Github access token:' TOKEN; echo $$TOKEN)

AUTH=${HOME}/.gem/credentials
GEM=${NAME}-${VERSION}.gem
GPR=https://rubygems.pkg.github.com/${OWNER}
SPEC=${NAME}.gemspec

all: publish

${AUTH}:
	@mkdir -p ${HOME}/.gem
	@echo '---' > $@
	@echo ':github: Bearer ${PAT}' >> $@
	@chmod 0600 $@

${GEM}: ${SPEC} ./lib/json_rails_logger/version.rb
	gem build ${SPEC}

auth: ${AUTH}

build: gem

gem: ${GEM}
	@echo ${GEM}

test: gem
	@bundle install
	@rake test

publish: ${GEM}
	@echo Publishing package ${NAME}:${VERSION} to ${OWNER} ...
	@gem push --key github --host ${GPR} ${GEM}
	@echo Done.

clean:
	@rm -rf ${GEM} 

realclean: clean
	@rm -rf ${AUTH} 
