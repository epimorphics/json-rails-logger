# frozen_string_literal: true

module JsonRailsLogger
  module Formatter
    # This class is the json formatter for our logger
    class Json < ::Logger::Formatter
      def call(severity, timestamp, _progname, raw_msg)
        msg = normalize_message(raw_msg)

        payload = {
          level: severity,
          timestamp: format_datetime(timestamp),
          environment: ::Rails.env,
          message: msg
        }

        "#{payload.to_json}\n"
      end

      private

      def normalize_message(raw_msg)
        return raw_msg unless raw_msg.is_a?(String)

        JSON.parse(raw_msg)
      rescue JSON::ParserError
        raw_msg
      end
    end
  end
end
