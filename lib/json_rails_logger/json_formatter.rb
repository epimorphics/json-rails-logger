# frozen_string_literal: true

module JsonRailsLogger
  # This class is the json formatter for our logger
  class JsonFormatter < ::Logger::Formatter
    def call(severity, timestamp, _progname, raw_msg)
      sev = process_severity(severity)
      timestp = process_timestamp(timestamp)
      msg = process_message(raw_msg)

      payload = { level: sev,
                  timestamp: timestp,
                  rails_environment: ::Rails.env }

      payload.merge!(x_request_id.to_h)
      payload.merge!(msg.to_h)

      "#{payload.to_json}\n"
    end

    private

    def process_severity(severity)
      { 'FATAL' => 'ERROR' }[severity] || severity
    end

    def process_timestamp(timestamp)
      format_datetime(timestamp)
    end

    def x_request_id
      x_request_id = Thread.current[JsonRailsLogger::REQUEST_ID]
      { 'x-request-id': x_request_id } if x_request_id
    end

    def process_message(raw_msg)
      msg = normalize_message(raw_msg)

      return msg unless msg.is_a?(String)

      return status_message(msg) if status_message?(msg)
      return get_message(msg) if get_message?(msg)
      return user_agent_message(msg) if user_agent_message?(msg)

      { message: msg.strip }
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
      status = msg.split(' ')[1]

      { status: status }
    end

    def get_message?(msg)
      msg.is_a?(String) &&
        msg.match(/GET http\S+/)
    end

    def get_message(msg)
      splitted_msg = msg.split(' ')
      method = splitted_msg[0]
      path = splitted_msg[1]

      { method: method, path: path }
    end

    def user_agent_message?(msg)
      msg.is_a?(String) &&
        msg.match(/User-Agent: .+Accept: .+/m)
    end

    def user_agent_message(msg)
      splitted_msg = msg.split("\n")
      user_agent = splitted_msg[0]&.split('"')&.at(1)
      accept = splitted_msg[1]&.split('"')&.at(1)

      { user_agent: user_agent, accept: accept }
    end
  end
end
