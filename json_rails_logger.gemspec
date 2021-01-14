# frozen_string_literal: true

require './lib/json_rails_logger/version'

Gem::Specification.new do |s|
  s.name        = 'json_rails_logger'
  s.version     = JsonRailsLogger::VERSION
  s.date        = '2021-01-06'
  s.summary     = 'JSON Rails Logger'
  s.description = 'A custom rails logger that outputs JSON instead of raw text'
  s.authors     = ['Bogdan-Adrian Marc']
  s.email       = 'bogdan.marc@epimorphics.com'
  s.files       = ['./lib/json_rails_logger.rb']
  s.homepage    = 'https://github.com/epimorphics/json-rails-logger'
  s.license     = 'MIT'

  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'lograge'
  s.add_runtime_dependency 'railties'
end
