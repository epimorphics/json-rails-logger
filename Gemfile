# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in json_rails_logger.gemspec
gemspec

group :development, :test do
  gem 'rake'
  gem 'rubocop'
  gem 'rubocop-rake'
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
end

group :development do
  gem 'foreman'
  gem 'ruby-lsp'
  gem 'solargraph'
  # Original meta_request gem is broken. Using fork provided by rails_panel
  # (https://github.com/dejan/rails_panel/issues/209#issuecomment-2621877079_)
  gem 'meta_request', github: 'dejan/rails_panel', ref: 'meta_request-v0.8.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
end
