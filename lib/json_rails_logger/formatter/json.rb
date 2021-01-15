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

      def process_severity(severity)
        severity.is_a?(String) && severity.match('FATAL') ? 'ERROR' : severity
      end

      def process_timestamp(timestamp)
        format_datetime(timestamp)
      end

      def process_message(raw_msg)
        msg = normalize_message(raw_msg)

        return msg unless msg.is_a?(String)

        status_message(msg) ||
          get_message(msg) ||
          user_agent_message(msg) ||
          msg.strip
      end

      def normalize_message(raw_msg)
        return raw_msg unless raw_msg.is_a?(String)

        JSON.parse(raw_msg)
      rescue JSON::ParserError
        raw_msg
      end

      def status_message(msg)
        status = msg.split(' ')[1]
        { status: status } if msg.match(/Status [0-9]+/)
      end

      def get_message(msg)
        splitted_msg = msg.split(' ')
        method = splitted_msg[0]
        path = splitted_msg[1]

        unless msg.split(' ').length == 2 && msg.split(' ')[0]&.match('GET')
          return nil
        end

        { method: method, path: path }
      end

      def user_agent_message(msg)
        splitted_msg = msg.split("\n")
        user_agent = splitted_msg[0]&.split('"')&.at(1)
        accept = splitted_msg[1]&.split('"')&.at(1)

        unless msg.split(' ')[0]&.match('User-Agent:') &&
               splitted_msg[1]&.split(' ')&.at(0)&.match('Accept:')
          return nil
        end

        { user_agent: user_agent, accept: accept }
      end
    end
  end
end
