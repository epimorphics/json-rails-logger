.PHONY: auth clean gem publish test

NAME?=json_rails_logger
OWNER?=epimorphics
VERSION?=$(shell ruby -e 'require "./lib/json_rails_logger/version" ; puts JsonRailsLogger::VERSION')
PAT?=$(shell read -p 'Github access token:' TOKEN; echo $$TOKEN)

AUTH=${HOME}/.gem/credentials
GEM=${NAME}-${VERSION}.gem
GPR=https://rubygems.pkg.github.com/${OWNER}
SPEC=${NAME}.gemspec

all: publish

${AUTH}:
	@mkdir -p ${HOME}/.gem
	@echo '---' > ${AUTH}
	@echo ':github: Bearer ${PAT}' >> ${AUTH}
	@chmod 0600 ${AUTH}

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
