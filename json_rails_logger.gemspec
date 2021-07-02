# frozen_string_literal: true

require './lib/json_rails_logger/version'

Gem::Specification.new do |s|
  s.name        = JsonRailsLogger::NAME
  s.version     = JsonRailsLogger::VERSION
  s.date        = '2021-01-06'
  s.summary     = 'JSON Rails Logger'
  s.description = 'A custom rails logger that outputs JSON instead of raw text'
  s.authors     = ['Bogdan-Adrian Marc']
  s.email       = 'bogdan.marc@epimorphics.com'
  s.files       = [
    './lib/json_rails_logger.rb',
    './lib/json_rails_logger/constants.rb',
    './lib/json_rails_logger/error.rb',
    './lib/json_rails_logger/json_formatter.rb',
    './lib/json_rails_logger/logger.rb',
    './lib/json_rails_logger/railtie.rb',
    './lib/json_rails_logger/request_id_middleware.rb',
    './lib/json_rails_logger/version.rb'
  ]
  s.homepage    = 'https://github.com/epimorphics/json-rails-logger'
  s.license     = 'MIT'

  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'lograge'
  s.add_runtime_dependency 'railties'

  s.add_development_dependency 'rake'
  s.metadata = { 'github_repo' => 'git@github.com:epimorphics/json-rails-logger.git' }
end
