# frozen_string_literal: true

module JsonRailsLogger
  # This class is the json formatter for our logger
  class JsonFormatter < ::Logger::Formatter # rubocop:disable Metrics/ClassLength
    ## Required keys to be logged to the output
    REQUIRED_KEYS = %w[
      accept
      backtrace
      body
      duration
      message
      method
      path
      query_string
      request_id
      request_params
      request_path
      request_status
      request_time
      status
      user_agent
    ].freeze

    ## Optional keys to be ignored from the output for the time being
    OPTIONAL_KEYS = %w[
      action
      encoding
      exception
      exception_object
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
      view
    ].freeze

    ## Request methods to check for in the message
    REQUEST_METHODS = %w[GET POST PUT DELETE PATCH].freeze

    # rubocop:disable Metrics/MethodLength
    def call(severity, timestamp, _progname, raw_msg) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      sev = process_severity(severity)
      timestp = process_timestamp(timestamp)
      msg = process_message(raw_msg)
      new_msg = format_message(msg).transform_keys(&:to_sym)

      # * Uncomment to print out the raw, processed and formatted messages to the console
      # if Rails.logger.debug?
      #   puts "\n\e[41m> received raw_msg: #{raw_msg}\e[0m"
      #   puts "\e[32m> processed msg: #{msg}\e[0m"
      #   puts "\e[33m> formatted new msg: #{new_msg}\e[0m\n\n"
      # end

      payload = {
        ts: timestp,
        level: sev
      }

      # ! SET THIS MESSAGE FROM WEBPACKER TO DEBUG LIKE THE DEVELOPERS SHOULD HAVE!
      if new_msg[:message] == "[Webpacker] Everything's up-to-date. Nothing to do"
        payload[:level] = 'DEBUG'
      end

      # ! SET THIS MESSAGE FROM RAILS TO DEBUG AS IT CONTAINS ONLY BASE INFORMATION!
      if new_msg[:optional].present? && new_msg[:optional].respond_to?(:[])
        new_msg[:message] = process_optional_messages(new_msg)
        new_msg[:request_status] = 'completed' if new_msg[:request_status].nil?
        payload[:level] = 'DEBUG'
      end

      # * Add the request time to the message if it is present and does not already contain it
      if new_msg[:request_time].present? && new_msg[:message].present? && new_msg[:message].exclude?(', time taken:') # rubocop:disable Layout/LineLength
        new_msg[:message] += format(', time taken: %.0f ms', new_msg[:request_time])
        seconds, milliseconds = new_msg[:request_time].divmod(1000)
        new_msg[:request_time] = format('%.0f.%03d', seconds, milliseconds) # rubocop:disable Style/FormatStringToken
      end

      payload.merge!(query_string.to_h) unless query_string.nil?
      payload.merge!(request_params.to_h) unless request_params.nil?
      payload.merge!(request_id.to_h)
      payload.merge!(new_msg.sort.to_h.except!(:optional).compact)

      "#{payload.to_json}\n"
    end
    # rubocop:enable Metrics/MethodLength

    private

    def process_severity(severity)
      { 'FATAL' => 'ERROR' }[severity] || severity
    end

    def process_timestamp(timestamp)
      format_datetime(timestamp.utc)
    end

    def request_id
      request_id = Thread.current[JsonRailsLogger::REQUEST_ID]
      { request_id: request_id } if request_id
    end

    def query_string
      query_string = Thread.current[JsonRailsLogger::QUERY_STRING]
      { query_string: query_string } if query_string.present?
    end

    def request_params
      request_params = Thread.current[JsonRailsLogger::REQUEST_PARAMS]
      request_params ||= Thread.current[JsonRailsLogger::PARAMS]
      { query_string: request_params } if request_params.present? && query_string.empty
    end

    def process_message(raw_msg)
      msg = normalize_message(raw_msg)

      return msg unless msg.is_a?(String)
      return status_message(msg) if status_message?(msg)
      return request_type(msg) if request_type?(msg)
      return user_agent_message(msg) if user_agent_message?(msg)

      # squish is better than strip as it still returns the string, but first
      # removing all whitespace on both ends of the string, and then changing
      # remaining consecutive whitespace groups into one space each. strip only
      # removes white spaces only at the leading and trailing ends.
      { message: msg.squish }
    end

    def process_optional_messages(msg) # rubocop:disable Metrics/AbcSize
      tmp_msg = msg[:message]

      if msg[:optional]['action'].present? && msg[:optional]['controller'].present?
        tmp_msg = "Completed#{format(' %s', msg[:optional]['action'])} action"
        tmp_msg += " for #{msg[:optional]['controller']}"
      end

      if msg[:optional]['request_uri'].present?
        tmp_msg.insert(tmp_msg.index(','), format(' to %s', msg[:optional]['request_uri']))
      end

      tmp_msg
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def format_message(msg)
      new_msg = { optional: {} }

      return msg.merge(new_msg) if string_message_field?(msg)

      return new_msg.merge(msg) unless msg.is_a?(Enumerable)

      # If the message is a hash, check if it contains the required keys
      split_msg = msg.partition { |k, _v| REQUIRED_KEYS.include?(k.to_s) }.map(&:to_h)
      # If the returned hash is empty, check if the message is a hash with optional keys
      if split_msg[0].empty?
        split_msg = msg.partition { |k, _v| OPTIONAL_KEYS.include?(k.to_s) }.map(&:to_h)
      end

      # Check if the message contains a duration key and normalise it
      split_msg[0] = normalise_duration(split_msg[0]) if includes_duration?(split_msg[0])

      new_msg.merge!(split_msg[0])
      new_msg[:optional].merge!(split_msg[1])

      new_msg
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
      msg.is_a?(String) &&
        msg.downcase.match(/status [0-9]+/)
    end

    def status_message(msg)
      status = msg.split[1]

      { status: status }
    end

    def request_type?(msg)
      msg.is_a?(String) &&
        REQUEST_METHODS.any? { |method| msg.match(/#{method} http\S+/) }
    end

    def request_type(msg)
      splitted_msg = msg.split
      method = splitted_msg[0]
      path = splitted_msg[1]
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

    def includes_duration?(msg)
      msg.key?('duration') ||
        msg.key?(:duration) ||
        msg.key?('request_time') ||
        msg.key?(:request_time)
    end

    # If duration is a float, convert it to an integer as milliseconds µs -> ms
    def normalise_duration(msg)
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
