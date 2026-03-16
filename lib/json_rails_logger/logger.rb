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
    #
    # @param formatter [Logger::Formatter, nil] Optional formatter override.
    #   Provide this only when replacing the entire formatting strategy.
    #   When omitted, the logger builds {JsonRailsLogger::JsonFormatter} using
    #   `filtered_keys:` and `keep_filtered_keys:`.
    #
    # @param filtered_keys [Array<String, Symbol>, nil] Optional key names to
    #   filter from log output when using the built-in formatter.
    #
    # @param keep_filtered_keys [Boolean] Whether filtered keys should be
    #   preserved under `:_filtered` for debugging when using the built-in
    #   formatter. Default is false.
    #
    # @return [JsonRailsLogger::Logger] A configured logger instance
    #
    # @example Basic usage in Rails environment config
    #   config.logger = JsonRailsLogger::Logger.new(STDOUT)
    #
    # @example With built-in key filtering
    #   config.logger = JsonRailsLogger::Logger.new(
    #     STDOUT,
    #     filtered_keys: %w[password api_key],
    #     keep_filtered_keys: true
    #   )
    #
    # @example With a custom formatter
    #   config.logger = JsonRailsLogger::Logger.new(
    #     STDOUT,
    #     formatter: MyCustomFormatter.new
    #   )
    #
    # @see https://guides.rubyonrails.org/debugging_rails_applications.html#the-logger
    # @see JsonFormatter#initialize
    def initialize(logdev, formatter: nil, filtered_keys: nil, keep_filtered_keys: false, **kwargs)
      # Use provided formatter, otherwise build the default JSON formatter.
      resolved_formatter = formatter || JsonRailsLogger::JsonFormatter.new(
        filtered_keys: filtered_keys,
        keep_filtered_keys: keep_filtered_keys
      )

      # Keep ISO 8601 with milliseconds and UTC timezone for formatter instances
      # that support datetime_format.
      if resolved_formatter.respond_to?(:datetime_format=)
        resolved_formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'
      end

      # Call the parent constructor with logdev and formatter.
      super(logdev, **kwargs.merge(formatter: resolved_formatter))

      # Keep local formatter reference consistent with ActiveSupport::Logger.
      @formatter = resolved_formatter
    end
  end
end
