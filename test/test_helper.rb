# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# enable if required during debugging
# require 'byebug'

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/autorun'

require 'logger'
require 'json'
require 'rails'

# Suppress lograge gem's method redefinition warnings during load
old_verbose = $VERBOSE
$VERBOSE = nil
require 'lograge' unless defined?(Lograge)
$VERBOSE = old_verbose

require 'json_rails_logger'
