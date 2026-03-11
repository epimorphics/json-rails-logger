# frozen_string_literal: true

module JsonRailsLogger
  # The custom logger class that sets up our formatter
  class Logger < ActiveSupport::Logger
    # Initialises a JSON logger for Rails applications
    #
    # Creates a logger that outputs all messages in JSON format compatible with
    # Epimorphics' logging infrastructure and ElasticSearch aggregation. All log
    # messages are formatted with ISO 8601 timestamps, request IDs, and structured
    # field extraction from log messages.
    #
    # @param logdev [IO, String, File] The output device to write log messages to.
    #   Typically STDOUT for production, or a file path for file-based logging.
    # @param include_ignored_keys [Boolean] Whether to include ignored fields in JSON output.
    #   ignored fields include user_agent, accept, controller, action, and other HTTP
    #   header information. Defaults to false for backward compatibility.
    #
    # @return [JsonRailsLogger::Logger] A configured logger instance
    #
    # @example Basic usage in Rails environment config
    #   config.logger = JsonRailsLogger::Logger.new(STDOUT)
    #
    # @example With ignored fields enabled for development
    #   config.logger = JsonRailsLogger::Logger.new(STDOUT, include_ignored_keys: true)
    #
    # @see https://guides.rubyonrails.org/debugging_rails_applications.html#the-logger
    # @see JsonFormatter#initialize
    def initialize(logdev, include_ignored_keys: false)
      # Set up the formatter to use our custom JSON formatter
      formatter = JsonRailsLogger::JsonFormatter.new(include_ignored_keys: include_ignored_keys)
      # and set the datetime format to ISO 8601 with milliseconds and UTC timezone
      formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'
      # Call the parent constructor with the logdev and formatter
      super(logdev, formatter: formatter)
      # Set the formatter to our custom JSON formatter
      @formatter = formatter
    end
  end
end
