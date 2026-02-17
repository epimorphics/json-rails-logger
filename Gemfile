# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in json_rails_logger.gemspec
gemspec

group :maintenance do
  gem 'json'
  gem 'lograge'
  gem 'railties'
end

group :development, :test do
  gem 'rake'
  gem 'rubocop'
  gem 'rubocop-rake'
  gem 'simplecov', require: false
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
end

group :development do
  gem 'foreman'
  gem 'ruby-lsp'
  gem 'solargraph'
end
