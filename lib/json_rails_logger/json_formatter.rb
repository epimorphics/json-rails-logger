# frozen_string_literal: true

module JsonRailsLogger
  # This class is the json formatter for our logger
  class JsonFormatter < ::Logger::Formatter
    COMMON_KEYS = %w[
      method path status duration user_agent accept request_id
    ].freeze

    def call(severity, timestamp, _progname, raw_msg)
      sev = process_severity(severity)
      timestp = process_timestamp(timestamp)
      msg = process_message(raw_msg)
      new_msg = format_message(msg)

      payload = { ts: timestp,
                  level: sev}

      payload.merge!(request_id.to_h)
      payload.merge!(new_msg.to_h)

      "#{payload.to_json}\n"
    end

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
      return get_message(msg) if get_message?(msg)
      return user_agent_message(msg) if user_agent_message?(msg)

      { message: msg.squish }
    end

    # rubocop:disable Metrics/AbcSize
    def format_message(msg)
      new_msg = {}

      return msg.merge(new_msg) if string_message_field?(msg)

      return new_msg.merge(msg) if !msg.is_a?(Enumerable)

      split_msg = msg.partition { |k, _v| COMMON_KEYS.include?(k.to_s) }.map(&:to_h)

      # If duration is a float, convert it to an integer as microseconds
      split_msg[0] = normalise_duration(split_msg[0]) if includes_duration?(split_msg[0])

      new_msg.merge!(split_msg[0])

      new_msg
    end
    # rubocop:enable Metrics/AbcSize

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

    def get_message?(msg)
      msg.is_a?(String) &&
        msg.match(/GET http\S+/)
    end

    def get_message(msg)
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

    def normalise_duration(msg)
      msg.to_h { |k, v| k.to_s == 'duration' && v.is_a?(Float) ? [k, (v * 1000).round(0)] : [k, v] }
    end
  end
end
