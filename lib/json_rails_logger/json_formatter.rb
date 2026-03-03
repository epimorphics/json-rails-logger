# frozen_string_literal: true

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

    ## Ignored keys to be omitted from the output for the time being
    IGNORED_KEYS = %w[
      accept
      action
      controller
      db
      encoding
      format
      forwarded_for
      gateway
      http_accept_charset
      http_accept_encoding
      http_accept_language
      http_cache_control
      http_charset
      http_cookie
      http_connection
      http_host
      http_origin
      http_referer
      keep_alive
      params
      remote_addr
      request_uri
      request_url
      server_name
      server_port
      server_protocol
      server_software
      user_agent
      view
    ].freeze

    ## Request methods to check for in the message
    REQUEST_METHODS = %w[GET POST PUT DELETE PATCH].freeze

    # Initialises a JSON formatter for Rails logging
    #
    # The formatter is responsible for converting log messages into JSON format
    # that includes extracted request metadata, status codes, user agent information,
    # and other relevant fields for operational monitoring.
    #
    # @param include_ignored_keys [Boolean] Whether to include ignored fields in formatted output.
    #   When true, fields like user_agent, accept, controller, and action are included.
    #   When false (default), only required fields are output. Set to true during
    #   development or debugging for detailed request information.
    #
    # @return [JsonRailsLogger::JsonFormatter] A configured formatter instance
    #
    # @example Create formatter with ignored fields
    #   formatter = JsonRailsLogger::JsonFormatter.new(include_ignored_keys: true)
    #   formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'
    #
    # @see https://ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html
    def initialize(include_ignored_keys: false)
      super() # dont pass any arguments to the parent class as it does not expect any
      @include_ignored_keys = include_ignored_keys
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
    #   - A Hash with structured data (split into required/ignored fields)
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
    # @example With ignored fields included
    #   formatter = JsonFormatter.new(include_ignored_keys: true)
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

      # ! SET THIS MESSAGE FROM RAILS TO DEBUG AS IT CONTAINS ONLY BASE INFORMATION!
      if new_msg[:ignored].present? && new_msg[:ignored].respond_to?(:[])
        new_msg[:message] = process_ignored_keys(new_msg)
        new_msg[:request_status] = 'completed' if new_msg[:request_status].nil?
      end

      # * Add the request time to the message if it is present and does not already contain it
      if new_msg[:request_time].present? && new_msg[:message].present? && !new_msg[:message].include?(', time taken:') # rubocop:disable Layout/LineLength
        new_msg[:message] += format(', time taken: %.0f ms', new_msg[:request_time])
        seconds, milliseconds = new_msg[:request_time].to_i.divmod(1000)
        new_msg[:request_time] = format('%.0f.%03d', seconds, milliseconds) # rubocop:disable Style/FormatStringToken
      end

      payload.merge!(query_string.to_h) unless query_string.nil?
      payload.merge!(request_params.to_h) unless request_params.nil?
      payload.merge!(request_id.to_h)
      payload.merge!(new_msg.sort.to_h.except!(:ignored).compact)
      payload.merge!(new_msg[:ignored]) if @include_ignored_keys && new_msg[:ignored].present?

      # * Reorder so ts and level come first after all processing is done
      final_payload = {
        ts: payload[:ts],
        level: payload[:level]
      }.merge(payload.except(:ts, :level))

      # * Convert the final payload to JSON and add a newline character at the end for better readability in the logs
      "#{final_payload.to_json}\n"
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

    def partition_message_by_keys(msg)
      # First try to partition by required keys
      split = msg.partition { |k, _v| REQUIRED_KEYS.include?(k.to_s) }.map(&:to_h)

      # If no required keys found, try partitioning by ignored keys instead
      return split unless split[0].empty?

      msg.partition { |k, _v| IGNORED_KEYS.include?(k.to_s) }.map(&:to_h)
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

    # Extract the request parameters from thread storage and include them in the log output if present and query string is blank
    def request_params
      request_params = Thread.current[JsonRailsLogger::REQUEST_PARAMS]
      request_params ||= Thread.current[JsonRailsLogger::PARAMS]
      { request_params: request_params } if request_params.present? && query_string.blank?
    end

    # Process the raw message input and extract relevant fields based on its content and format
    def process_message(raw_msg)
      # If the message is nil, return an empty hash
      return {} if raw_msg.nil?

      # Otherwise, normalize the message
      msg = normalize_message(raw_msg)

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

    # Process ignored keys to create a more user-friendly message for completed requests, including the controller, action, and request URI if available
    def process_ignored_keys(msg) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      tmp_msg = msg[:message]
      ignored = msg[:ignored]

      # Check for both string and symbol keys to handle different input formats
      action = ignored['action'] || ignored[:action]
      controller = ignored['controller'] || ignored[:controller]
      request_uri = ignored['request_uri'] || ignored[:request_uri]

      if action.present? && controller.present?
        # Extract controller name: Api::TransformationsController → Transformations
        controller_name = controller.to_s.gsub('Controller', '').split('::').last
        tmp_msg = "#{controller_name} #{action} request complete"
      end

      # If request_uri is present, add it to the message for better context
      tmp_msg.insert(tmp_msg.index(','), format(' to %s', request_uri)) if request_uri.present?

      # return the formatted message if any ignored keys are present, otherwise return the original message
      if IGNORED_KEYS.any? { |key| ignored.key?(key) || ignored.key?(key.to_sym) }
        tmp_msg
      else
        msg[:message]
      end
    end

    # Format the message by separating required and ignored fields, normalizing status and duration, and preparing the final structure for JSON output
    def format_message(msg)
      new_msg = { ignored: {} }

      return msg.merge(new_msg) if string_message_field?(msg)

      return new_msg.merge(msg) unless msg.is_a?(Enumerable)

      # If the message is a hash, check if it contains the required keys
      split_msg =  partition_message_by_keys(msg)
      # Check if the message contains a timing key and normalise it
      split_msg[0] = normalise_timing(split_msg[0]) if includes_timing?(split_msg[0])

      new_msg.merge!(split_msg[0])
      new_msg[:ignored].merge!(split_msg[1])

      new_msg
    end

    # Check if the message is a hash with a single key :message with a string value
    # @param msg [Hash] the message to check
    # @return [Boolean] true if the message is a hash with a single key :message with a string value, false otherwise
    def string_message_field?(msg)
      msg.is_a?(Hash) &&
        msg.length == 1 &&
        msg.fetch(:message, nil).is_a?(String)
    end

    def normalize_message(raw_msg)
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
      msg.to_h do |k, v|
        if %w[duration request_time].include?(k.to_s) && v.is_a?(Float)
          [:request_time, v.round(0)]
        else
          [k, v]
        end
      end
    end
  end
end
