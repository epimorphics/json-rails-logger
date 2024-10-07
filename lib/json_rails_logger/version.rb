# frozen_string_literal: true

module JsonRailsLogger
  MAJOR = 1
  MINOR = 1
  PATCH = 0
  SUFFIX = 'rc01'
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}#{SUFFIX && "-#{SUFFIX}"}"
end
