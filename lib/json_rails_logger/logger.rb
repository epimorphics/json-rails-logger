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
      # Set up the formatter to use our custom JSON formatter
      formatter = JsonRailsLogger::JsonFormatter.new
      # and set the datetime format to ISO 8601 with milliseconds and UTC timezone
      formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'
      # Call the parent constructor with the logdev and formatter
      super(logdev, formatter: formatter)
      # Set the formatter to our custom JSON formatter
      @formatter = formatter
    end
  end
end
