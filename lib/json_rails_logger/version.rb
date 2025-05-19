# frozen_string_literal: true

module JsonRailsLogger
  MAJOR = 2
  MINOR = 0
  PATCH = 6
  SUFFIX = nil
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}#{SUFFIX && "-#{SUFFIX}"}".freeze
end
