# frozen_string_literal: true

# Namespace for JSON logger components used by Rails integrations.
module JsonRailsLogger
  # This class is the json formatter for our logger
  class JsonFormatter < ::Logger::Formatter # rubocop:disable Metrics/ClassLength
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
    def call(severity, timestamp, progname, raw_msg) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      sev = process_severity(severity)
      tmstmp = process_timestamp(timestamp)
      prgname = process_progname(progname)
      msg = process_message(raw_msg)
      msg[:progname] = prgname if prgname
      msg[:level] = sev.ljust(5).squish if sev
      new_msg = format_message(msg).transform_keys(&:to_sym)

      # * Start building the payload with the timestamp and then merge in the other fields as they are processed
      payload = { ts: tmstmp }

      # Append request context details to the message when present
      if new_msg[:action].present? || new_msg[:controller].present?
        new_msg[:message] = append_request_details(new_msg)
        new_msg[:request_status] = 'completed' if new_msg[:request_status].nil?
      end

      # * Add the request time to the message if it is present and does not
      #   already contain it
      if new_msg[:request_time].present? && new_msg[:message].present? && !new_msg[:message].include?(', time taken:') # rubocop:disable Layout/LineLength
        new_msg[:message] += format(', time taken: %.0f ms', new_msg[:request_time])
        seconds, milliseconds = new_msg[:request_time].to_i.divmod(1000)
        new_msg[:request_time] = format('%.0f.%03d', seconds, milliseconds) # rubocop:disable Style/FormatStringToken
      end

      # * Merge in the query string and request params if they are present in
      #   thread storage, giving precedence to request params if both are
      #   present. This ensures that we capture the most relevant request
      #   metadata for log analysis.
      payload.merge!(query_string.to_h) unless query_string.nil?
      payload.merge!(request_params.to_h) unless request_params.nil?
      payload.merge!(request_id.to_h)
      payload.merge!(new_msg.sort.to_h.compact)

      # * Reorder so ts and level come first after all processing is done
      final_payload = {
        ts: payload[:ts],
        level: payload[:level]
      }.merge(payload.except(:ts, :level))

      # * Convert the final payload to JSON and add a newline character at the
      #   end for better readability in the logs
      "#{final_payload.to_json}\n"
    rescue JSON::NestingError
      raise JSON::GeneratorError, 'circular reference detected'
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

    def ensure_required_keys(msg)
      msg = msg.to_h if msg.respond_to?(:to_h)
      REQUIRED_KEYS.each do |key|
        key_sym = key.to_sym
        msg[key_sym] = msg[key_sym] || msg[key.to_s] || nil unless msg.key?(key_sym)
      end
      msg
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

    # Extract the request ID from thread storage and include it in the log output if present
    def request_id
      request_id = Thread.current[JsonRailsLogger::REQUEST_ID]
      { request_id: request_id } if request_id
    end

    # Extract the query string from thread storage and include it in the log output if present
    def query_string
      query_string ||= Thread.current[JsonRailsLogger::QUERY_STRING]
      { query_string: query_string } if query_string.present?
    end

    # Extract the request parameters from thread storage and include them in the log output if present
    def request_params
      request_params = Thread.current[JsonRailsLogger::REQUEST_PARAMS]
      request_params ||= Thread.current[JsonRailsLogger::PARAMS]
      { request_params: request_params } if request_params.present?
    end

    # Process the raw message input and extract relevant fields based on its content and format
    def process_message(raw_msg)
      # If the message is nil, return an empty hash
      return {} if raw_msg.nil?

      # Otherwise, normalise the message
      msg = normalise_message(raw_msg)

      return msg unless msg.is_a?(String)
      return status_message(msg) if status_message?(msg)
      return request_type(msg) if request_type?(msg)
      return user_agent_message(msg) if user_agent_message?(msg)

      # Clean up the message if it contains special characters
      msg = remove_unprintable_characters(msg)

      # squish is better than strip as it still returns the string, but first
      # removing all whitespace on both ends of the string, and then changing
      # remaining consecutive whitespace groups into one space each. strip only
      # removes white spaces only at the leading and trailing ends.
      { message: msg.squish }
    end

    # Remove unprintable characters from the message to prevent JSON serialization issues and ensure clean log output
    def remove_unprintable_characters(msg)
      # Remove ANSI escape codes
      msg = msg.gsub(/\e\[[0-9;]*m/, '') if msg.match?(/\e\[[0-9;]*m/)
      # Remove all non-printable characters
      msg = msg.gsub(/[^[:print:]]/, '') if msg.match?(/[^[:print:]]/)
      # Remove all non-ASCII characters
      msg = msg.gsub(/[^\x00-\x7F]/, '') if msg.match?(/[^\x00-\x7F]/)

      msg
    end

    # Builds a message from controller and action names
    def build_controller_action_message(action, controller, original_message)
      return original_message if action.blank? || controller.blank?

      controller_name = controller.to_s.gsub('Controller', '').split('::').last
      "#{controller_name} #{action} request complete"
    end

    # Appends request URI to the message when available.
    def append_request_uri(message, request_uri)
      return message if request_uri.blank?

      # If request_uri is present, append it to the message for better context
      message + format(' to %s', request_uri)
    end

    # Appends request context information to the log message
    def append_request_details(msg)
      action = msg['action'] || msg[:action]
      controller = msg['controller'] || msg[:controller]
      request_uri = msg['request_uri'] || msg[:request_uri]

      tmp_msg = build_controller_action_message(action, controller, msg[:message]) || ''
      append_request_uri(tmp_msg, request_uri)
    end

    # Format the message by ensuring required fields are present and normalising timing values
    def format_message(msg)
      return msg if string_message_field?(msg)
      return {} unless msg.is_a?(Enumerable)

      msg = ensure_required_keys(msg)
      msg = normalise_timing(msg) if includes_timing?(msg)

      msg
    end

    # Check if the message is a hash with a single key :message with a string value
    # @param msg [Hash] the message to check
    # @return [Boolean] true if the message is a hash with a single key :message with a string value, false otherwise
    def string_message_field?(msg)
      msg.is_a?(Hash) &&
        msg.length == 1 &&
        msg.fetch(:message, nil).is_a?(String)
    end

    def normalise_message(raw_msg)
      return raw_msg unless raw_msg.is_a?(String)

      JSON.parse(raw_msg)
    rescue JSON::ParserError
      raw_msg
    end

    def status_message?(msg)
      # puts "Checking for status message in: #{msg}" if Rails.logger.debug?
      msg.is_a?(String) &&
        msg.downcase.match(/status [0-9]+/)
    end

    def status_message(msg)
      # puts "Found status message in: #{msg}" if Rails.logger.debug?
      split_status = msg.split
      # puts "Split status message: #{split_status}" if Rails.logger.debug?
      is_status = split_status[0] == 'response:'
      code = split_status[is_status ? 2 : 1]

      status = code.to_i

      { status: status }
    end

    def request_type?(msg)
      # puts "Checking for request type in: #{msg}" if Rails.logger.debug?
      msg.is_a?(String) &&
        REQUEST_METHODS.any? { |method| msg.match(/#{method} http\S+/) }
    end

    def request_type(msg)
      # puts "Found request type in: #{msg}" if Rails.logger.debug?
      split_type = msg.split
      # puts "Split type: #{split_type}" if Rails.logger.debug?
      is_request = split_type[0] == 'request:'
      method = split_type[is_request ? 1 : 0]
      path = split_type[is_request ? 2 : 1]
      { method: method, path: path }
    end

    def user_agent_message?(msg)
      msg.is_a?(String) &&
        msg.downcase.match(/user-agent: .[\S\s]+accept: .+/m)
    end

    def user_agent_message(msg)
      splitted_msg = msg.split("\n")
      user_agent = splitted_msg[0]&.split('"')&.at(1)
      accept = splitted_msg[1]&.split('"')&.at(1)

      { user_agent: user_agent, accept: accept }
    end

    def includes_timing?(msg)
      msg.key?('duration') ||
        msg.key?(:duration) ||
        msg.key?('request_time') ||
        msg.key?(:request_time)
    end

    # If request_time is a float, convert it to an integer as milliseconds µs -> ms
    # Duration is already in milliseconds from Lograge, so preserve it as-is
    def normalise_timing(msg)
      result = msg.to_h { |k, v| [k, v] }

      if result[:request_time].nil? && result[:duration].is_a?(Float)
        result[:request_time] = result[:duration].round(0)
      elsif result[:request_time].is_a?(Float)
        result[:request_time] = result[:request_time].round(0)
      end

      result
    end
  end
end
