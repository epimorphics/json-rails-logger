# frozen_string_literal: true

module JsonRailsLogger
  # The custom logger class that sets up our formatter
  class Logger < ActiveSupport::Logger
    # Initialize a logger which is opinionated about emitting log messages
    # in a standard JSON format that meets the expectations of Epimorphics
    # operations and monitoring tools
    #
    # +logdev+ The output device to send log messages to
    def initialize(logdev)
      formatter = JsonRailsLogger::JsonFormatter.new
      formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

      super(logdev, formatter: formatter)
      @formatter = formatter
    end
  end
end
