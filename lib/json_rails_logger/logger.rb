# frozen_string_literal: true

require 'logger'

module JsonRailsLogger
  # The custom logger class that sets up our formatter
  class Logger < ::Logger
    # List of all the arguments with their default values:
    # logdev, shift_age = 0, shift_size = 1_048_576, level: DEBUG,
    # progname: nil, formatter: nil, datetime_format: nil,
    # binmode: false, shift_period_suffix: '%Y%m%d'
    def initialize(*args)
      @formatter = JsonRailsLogger::Formatter::Json.new
      @formatter.datetime_format = '%Y-%m-%d %H:%M:%S'

      super(*args, formatter: @formatter)
    end
  end
end
