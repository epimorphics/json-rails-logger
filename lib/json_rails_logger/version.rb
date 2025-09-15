# frozen_string_literal: true

module JsonRailsLogger
  MAJOR = 2
  MINOR = 2
  PATCH = 0
  SUFFIX = nil
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}#{SUFFIX && "-#{SUFFIX}"}".freeze
end
