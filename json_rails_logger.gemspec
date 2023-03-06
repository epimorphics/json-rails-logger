# frozen_string_literal: true

require './lib/json_rails_logger/version'

Gem::Specification.new do |spec|
  spec.name        = 'json_rails_logger'
  spec.version     = JsonRailsLogger::VERSION
  spec.summary     = 'JSON Rails Logger'
  spec.description = 'A custom rails logger that outputs JSON instead of raw text'
  spec.authors     = ['Epimorphics Ltd', 'Bogdan-Adrian Marc']
  spec.email       = 'info@epimorphics.com'
  spec.homepage    = 'https://github.com/epimorphics/json-rails-logger'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 2.6'

  spec.metadata = {
    'github_repo' => 'git@github.com:epimorphics/json-rails-logger.git',
    'rubygems_mfa_required' => 'true'
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(.github/|.gitignore|features/|Makefile|spec/|test/)})
    end
  end
  spec.require_paths = ['lib']

  # * Resolves open-ended dependencies warning on `make publish`
  # * See https://guides.rubygems.org/specification-reference/ for more information.
  spec.add_runtime_dependency 'json', '~> 2.3.0'
  spec.add_runtime_dependency 'lograge', '~> 0.12.0'
  spec.add_runtime_dependency 'railties', '~> 7.0.0'

  spec.add_development_dependency 'rake', '~> 13.0.0'
end
