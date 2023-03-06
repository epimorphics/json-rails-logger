# frozen_string_literal: true

module JsonRailsLogger
  MAJOR = 0
  MINOR = 3
  PATCH = 5
  SUFFIX = 1
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}#{SUFFIX && '.' + SUFFIX.to_s}"

end
