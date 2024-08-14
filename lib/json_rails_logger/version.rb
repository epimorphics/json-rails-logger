# frozen_string_literal: true

module JsonRailsLogger
  MAJOR = 1
  MINOR = 0
  PATCH = 4
  SUFFIX = 'rc01'
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}#{SUFFIX && "-#{SUFFIX}"}"
end
