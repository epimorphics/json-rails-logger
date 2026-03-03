# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in json_rails_logger.gemspec
gemspec

# Runtime dependencies are mirrored here to make them "explicit" for bundler.
# This allows `bundle outdated --only-explicit` to check these dependencies,
# which would otherwise be treated as sub-dependencies from the gemspec.
group :maintenance do
  gem 'json', '>= 1.8', '< 5.0'      # works back to Ruby 2.x era
  gem 'lograge', '>= 0.10', '< 2.0'  # older but stable
  gem 'railties', '>= 6.0', '< 9.0'  # broadest Rails compatibility
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
