# frozen_string_literal: true

module JsonRailsLogger
  # Namespace for formatting components used to decompose JSON formatter logic
  module FormattingComponents
    # Assembles and serialises final JSON log payload from processed message components.
    #
    # Orchestrates payload construction for Epimorphics operational logging by merging
    # timestamp, request context (from thread storage), and formatted message data.
    # Enriches message strings with controller/action/request_time details when present,
    # orders fields (timestamp and level first), and serialises to JSON format with
    # trailing newline for structured log output.
    #
    # Used by JsonFormatter as the final step in log processing, after message parsing
    # and formatting are complete. Handles all payload assembly, field ordering, and
    # JSON serialisation concerns.
    #
    # @example Build payload with controller context
    #   builder = FormattingComponents::PayloadBuilder.new
    #   message = {
    #     level: "INFO",
    #     controller: "DatasetsController",
    #     action: "index",
    #     request_time: 45.0
    #   }
    #   builder.build(timestamp: "2026-03-04T10:30:00.000Z", message: message)
    #   # => "{\"ts\":\"2026-03-04T10:30:00.000Z\",\"level\":\"INFO\",...}\n"
    #
    # @example Build payload without request context
    #   builder.build(timestamp: "2026-03-04T10:30:00.000Z", message: { level: "DEBUG", message: "test" })
    #   # => "{\"ts\":\"2026-03-04T10:30:00.000Z\",\"level\":\"DEBUG\",\"message\":\"test\"}\n"
    #
    class PayloadBuilder
      # Builds and serialises the final JSON log payload.
      #
      # Assembles payload by:
      # 1. Starting with timestamp
      # 2. Enriching message with controller/action context (if present)
      # 3. Formatting and appending request_time to message string (if present)
      # 4. Merging request context from thread storage
      # 5. Merging formatted message
      # 6. Reordering fields (ts, level first)
      # 7. Serialising to JSON with trailing newline
      #
      # @param timestamp [String] ISO 8601 formatted timestamp with milliseconds
      # @param message [Hash] Processed and formatted message hash with symbolized keys.
      #   May include: :level, :message, :controller, :action, :request_time, etc.
      #
      # @return [String] JSON-formatted log line with trailing newline
      #
      # @raise [JSON::GeneratorError] If payload contains circular references
      #
      def build(timestamp:, message:)
        # Start building the payload with the timestamp
        payload = { ts: timestamp }

        # Enrich message with controller/action context when present
        enriched_message = enrich_message_with_request_details(message)

        # Merge request context from thread storage and processed message
        payload.merge!(FormattingComponents::RequestContext.collect)
        payload.merge!(enriched_message.sort.to_h.compact)

        # Reorder so ts and level come first after all processing is done
        final_payload = reorder_payload(payload)

        # Convert to JSON and add newline
        serialize_payload(final_payload)
      rescue JSON::NestingError
        raise JSON::GeneratorError, 'circular reference detected'
      end

      private

      # Enriches message with controller/action context and request timing information.
      #
      # If message contains controller or action fields, delegates to RequestMessageComposer
      # to build human-readable message string. If request_time is present, formats and
      # appends timing information to the message string.
      #
      # @param message [Hash] Message hash to enrich
      # @return [Hash] Enriched message with updated :message and :request_status fields
      #
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def enrich_message_with_request_details(message)
        enriched = message.dup

        # Append request context details to the message when present
        if enriched[:action].present? || enriched[:controller].present?
          enriched[:message] = FormattingComponents::RequestMessageComposer.new.include_component_details(enriched)
          enriched[:request_status] = 'completed' if enriched[:request_status].nil?
        end

        # Add request time to the message if present and not already included
        if enriched[:request_time].present? && enriched[:message].present? && !enriched[:message].include?(', time taken:') # rubocop:disable Layout/LineLength
          enriched[:message] += format(', time taken: %.0f ms', enriched[:request_time])
          seconds, milliseconds = enriched[:request_time].to_i.divmod(1000)
          enriched[:request_time] = format('%.0f.%03d', seconds, milliseconds) # rubocop:disable Style/FormatStringToken
        end

        enriched
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # Reorders payload to ensure timestamp and level appear first.
      #
      # Operational logs typically scan ts and level first for filtering/analysis,
      # so these fields are positioned at the beginning of the JSON output for
      # improved readability and parsing efficiency.
      #
      # @param payload [Hash] Unordered payload hash
      # @return [Hash] Reordered payload with ts and level first
      #
      def reorder_payload(payload)
        {
          ts: payload[:ts],
          level: payload[:level]
        }.merge(payload.except(:ts, :level))
      end

      # Serializes payload to JSON with trailing newline.
      #
      # @param payload [Hash] Payload to serialize
      # @return [String] JSON string with trailing newline
      #
      def serialize_payload(payload)
        "#{payload.to_json}\n"
      end
    end
  end
end
