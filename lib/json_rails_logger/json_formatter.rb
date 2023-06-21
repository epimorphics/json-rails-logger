# frozen_string_literal: true

module JsonRailsLogger
  # This class is the json formatter for our logger
  class JsonFormatter < ::Logger::Formatter
    ## Required keys to be logged to the output
    REQUIRED_KEYS = %w[
      method path status duration user_agent accept request_id request_url message
    ].freeze

    ## Optional keys to be ignored from the output for the time being
    OPTIONAL_KEYS = %w[format controller action view exception exception_object].freeze

    ## Request methods to check for in the message
    REQUEST_METHODS = %w[GET POST PUT DELETE PATCH].freeze

    # rubocop:disable Metrics/MethodLength
    def call(severity, timestamp, _progname, raw_msg)
      sev = process_severity(severity)
      timestp = process_timestamp(timestamp)
      msg = process_message(raw_msg)
      new_msg = format_message(msg)

      payload = {
        ts: timestp,
        level: sev
      }

      payload.merge!(request_id.to_h)
      payload.merge!(new_msg.to_h.except!(:optional).compact)

      "#{payload.to_json}\n"
      "\n#{payload.to_json}\n" if Rails.env.development?
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

    def process_message(raw_msg)
      msg = normalize_message(raw_msg)

      return msg unless msg.is_a?(String)
      return status_message(msg) if status_message?(msg)
      return request_type(msg) if request_type?(msg)
      return user_agent_message(msg) if user_agent_message?(msg)

      { message: msg.squish }
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def format_message(msg)
      new_msg = { optional: {} }

      return msg.merge(new_msg) if string_message_field?(msg)

      return new_msg.merge(msg) unless msg.is_a?(Enumerable)

      split_msg = msg.partition { |k, _v| REQUIRED_KEYS.include?(k.to_s) }.map(&:to_h)
      if split_msg[0].empty?
        split_msg = msg.partition do |k, _v|
          OPTIONAL_KEYS.exclude?(k.to_s)
        end.map(&:to_h)
      end

      split_msg[0] = normalise_duration(split_msg[0]) if includes_duration?(split_msg[0])

      new_msg.merge!(split_msg[0])
      new_msg[:optional].merge!(split_msg[1])

      new_msg
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
        msg.match(/Status [0-9]+/)
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
        msg.match(/User-Agent: .[\S\s]+Accept: .+/m)
    end

    def user_agent_message(msg)
      splitted_msg = msg.split("\n")
      user_agent = splitted_msg[0]&.split('"')&.at(1)
      accept = splitted_msg[1]&.split('"')&.at(1)

      { user_agent: user_agent, accept: accept }
    end

    def includes_duration?(msg)
      msg.key?('duration')
    end

    # If duration is a float, convert it to an integer as microseconds
    def normalise_duration(msg)
      msg.to_h { |k, v| k.to_s == 'duration' && v.is_a?(Float) ? [k, (v * 1000).round(0)] : [k, v] }
    end
  end
end
