# frozen_string_literal: true

module JsonRailsLogger
  # The custom logger class that sets up our formatter
  class Logger < ::Logger
    def initialize(logdev, shift_age = 0, shift_size = 1_048_576, level: DEBUG,
                   progname: nil, formatter: nil, datetime_format: nil,
                   binmode: false, shift_period_suffix: '%Y%m%d')
      @formatter = JsonRailsLogger::Formatter::Json.new
      @formatter.datetime_format = datetime_format
      super(logdev, shift_age, shift_size, level: level,
                                           progname: progname,
                                           formatter: @formatter,
                                           datetime_format: datetime_format,
                                           binmode: binmode,
                                           shift_period_suffix: shift_period_suffix)
    end
  end
end
