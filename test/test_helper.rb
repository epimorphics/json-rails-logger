# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# enable if required during debugging
# require 'byebug'

require 'minitest/autorun'

require 'logger'
require 'json'
require 'rails'
require 'lograge' unless defined?(Lograge)

require 'json_rails_logger'
