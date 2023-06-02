# frozen_string_literal: true

module JsonRailsLogger
  MAJOR = 1
  MINOR = 0
  PATCH = 0
  SUFFIX = nil
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}#{SUFFIX && '.' + SUFFIX.to_s}"
end
