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
  s.homepage    = 'https://github.com/epimorphics/json-rails-logger'
  s.license     = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(.github/|.gitignore|features/|Makefile|spec/|test/)})
    end
  end
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.6'

  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'lograge'
  s.add_runtime_dependency 'railties'

  s.add_development_dependency 'rake'

  s.metadata = { 'github_repo' => 'git@github.com:epimorphics/json-rails-logger.git',
                 'rubygems_mfa_required' => 'true' }
end
