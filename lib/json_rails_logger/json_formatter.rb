# frozen_string_literal: true

# Namespace for JSON logger components used by Rails integrations.
module JsonRailsLogger
  # This class is the json formatter for our logger
  class JsonFormatter < ::Logger::Formatter
    ## Required keys to be logged to the output
    REQUIRED_KEYS = %w[
      backtrace
      body
      duration
      exception
      exception_object
      level
      message
      method
      path
      query_string
      returned_rows
      request_id
      request_params
      request_path
      request_status
      request_time
      status
    ].freeze

    ## Request methods to check for in the message
    REQUEST_METHODS = %w[GET POST PUT DELETE PATCH].freeze

    # Initialises a JSON formatter for Rails logging
    #
    # The formatter is responsible for converting log messages into JSON format
    # that includes extracted request metadata, status codes, user agent information,
    # and other relevant fields for operational monitoring.
    #
    # @return [JsonRailsLogger::JsonFormatter] A configured formatter instance
    #
    # @example Create formatter
    #   formatter = JsonRailsLogger::JsonFormatter.new
    #   formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'
    #
    # @see https://ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html
    def initialize(**_opts)
      super # dont pass any arguments to the parent class as it does not expect any
      self.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'
    end

    # Formats a log message into JSON suitable for structured logging and analysis
    #
    # This is the primary method called by the Ruby Logger to format log output.
    # It processes the severity, timestamp, and message into a single-line JSON
    # string with automatically extracted request metadata (status codes, HTTP methods,
    # user agents, request IDs, etc.). The formatter is designed to work with Rails
    # controllers and Lograge event processing.
    #
    # The method handles several input formats and automatically extracts relevant
    # fields:
    # - Status messages ("Status 200") → extracts status code
    # - Request lines ("GET http://example.com") → extracts method and path
    # - User-Agent headers → extracts user_agent and accept fields
    #
    # @param severity [String, Integer] The log level as a string (DEBUG, INFO, WARN, ERROR, FATAL)
    #   or Logger::Severity constant (0-4). If nil, level field is omitted.
    # @param timestamp [Time] The time the log message was generated.
    #   Will be formatted as ISO 8601 with milliseconds (YYYY-MM-DDTHH:MM:SS.sssZ).
    # @param progname [String, nil] The program/gem name, typically auto-set by Rails.
    #   Included in output if present.
    # @param raw_msg [String, Hash, Object] The log message content. Can be:
    #   - A plain string (processed for status, request type, user-agent patterns)
    #   - A JSON string (parsed and merged into output)
    #   - A Hash with structured data (validated against required schema, all keys included in output)
    #   - Any object (converted to string via to_s)
    #
    # @return [String] A JSON-formatted log line with trailing newline (\n).
    #   Keys are ordered: ts, level first, then remaining fields alphabetically.
    #
    # @example String message (status extraction)
    #   formatter.call('INFO', Time.now, 'MyApp', 'Status 200')
    #   # => "{\"ts\":\"2026-02-24T10:30:45.123Z\",\"level\":\"INFO\",\"status\":200}\n"
    #
    # @example Hash message with request data
    #   msg = {method: 'POST', path: '/api/users', status: 201, request_time: 45.3}
    #   formatter.call('INFO', Time.now, 'Rails', msg)
    #   # => "{\"ts\":\"2026-02-24T10:30:45.123Z\",\"level\":\"INFO\",\"method\":\"POST\",...}\n"
    #
    # @example With user-agent and accept extraction
    #   formatter = JsonFormatter.new
    #   raw_msg = "User-Agent: \"Mozilla/5.0\"\nAccept: \"application/json\""
    #   formatter.call('INFO', Time.now, 'Rails', raw_msg)
    #   # => "{\"ts\":\"...\",\"level\":\"INFO\",\"user_agent\":\"Mozilla/5.0\",\"accept\":\"application/json\"}\n"
    #
    # @note The request_id from Thread.current[JsonRailsLogger::REQUEST_ID] is automatically
    #   included if available. This is set by the RequestIdMiddleware.
    #
    # @raise [JSON::GeneratorError] If the final payload cannot be serialized to JSON
    #   (rare; usually indicates circular references in custom log objects)
    #
    # @see Logger#initialize
    # @see RequestIdMiddleware
    # @see https://ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html#method-i-call
    # rubocop:disable Metrics/MethodLength
    def call(severity, timestamp, progname, raw_msg)
      sev = process_severity(severity)
      tmstmp = process_timestamp(timestamp)
      prgname = process_progname(progname)
      msg = process_message(raw_msg)
      msg[:progname] = prgname if prgname
      msg[:level] = sev.ljust(5).squish if sev
      new_msg = FormattingComponents::MessageValidator.new.validate(msg).transform_keys(&:to_sym)

      # Delegate payload assembly and serialisation to PayloadBuilder
      FormattingComponents::PayloadBuilder.new.build(
        timestamp: tmstmp,
        message: new_msg
      )
    end
    # rubocop:enable Metrics/MethodLength

    private

    def process_severity(severity)
      case severity
      when 0, 'DEBUG', 'TRACE' then 'DEBUG'
      when 1, 'INFO' then 'INFO'
      when 2, 'WARN' then 'WARN'
      when 3, 'ANY', 'UNKNOWN', 'CRITICAL', 'FATAL', 'ERROR' then 'ERROR'
      else
        severity
      end
    end

    def process_timestamp(timestamp)
      format_datetime(timestamp.utc)
    end

    # Process progname to remove the last space if it exists
    # @param progname [String] - Program name to include in log messages.
    # This is needed because the Rails logger adds a space at the end of the progname
    # and we need to remove it to avoid having a space at the end of the JSON string
    def process_progname(progname)
      # If the progname is nil, return nil
      return if progname.nil?

      # Make sure the progname is a string
      progname = progname.to_s
      # Remove the last space if it exists
      progname = progname[0..-2] if progname[-1] == ' '
      # Return the progname
      progname
    end

    # Process the raw message input by delegating to MessageParser
    def process_message(raw_msg)
      FormattingComponents::MessageParser.new.parse(raw_msg)
    end
  end
end
