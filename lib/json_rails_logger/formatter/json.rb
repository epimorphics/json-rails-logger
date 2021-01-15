# frozen_string_literal: true

module JsonRailsLogger
  module Formatter
    # This class is the json formatter for our logger
    class Json < ::Logger::Formatter
      def call(severity, timestamp, progname, raw_msg)
        args = process_arguments(severity, timestamp, progname, raw_msg)

        payload = {
          level: args[:severity],
          timestamp: args[:timestamp],
          environment: ::Rails.env,
          message: args[:msg]
        }

        "#{payload.to_json}\n"
      end

      private

      def process_arguments(severity, timestamp, progname, raw_msg)
        sev = process_severity(severity)
        timestp = process_timestamp(timestamp)
        new_msg = process_message(raw_msg)

        {
          severity: sev,
          timestamp: timestp,
          progname: progname,
          msg: new_msg
        }
      end
      def normalize_message(raw_msg)
        return raw_msg unless raw_msg.is_a?(String)

        JSON.parse(raw_msg)
      rescue JSON::ParserError
        raw_msg
      end
    end
  end
end
