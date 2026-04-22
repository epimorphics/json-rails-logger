# frozen_string_literal: true

module JsonRailsLogger
  MAJOR = 3
  MINOR = 0
  PATCH = 1
  SUFFIX = nil
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}#{SUFFIX && "-#{SUFFIX}"}".freeze
end
