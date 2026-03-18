# frozen_string_literal: true

module JsonRailsLogger
  # Namespace for formatting components used to deconstruct JSON formatter logic
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
      # Initialises a PayloadBuilder with optional filtering configuration.
      #
      # @param filtered_keys [Array<String, Symbol>, nil] Key patterns to filter from output.
      #   Each pattern can be a string (exact match) or symbol (converted to string for matching).
      #   When provided, keys matching these patterns are either removed or preserved for debugging.
      #   Default is nil (no filtering applied).
      #
      # @param keep_filtered_keys [Boolean] Whether to preserve filtered keys in debug output.
      #   When false (default), filtered keys are removed entirely from the payload.
      #   When true, filtered keys are collected and included under the :_filtered key
      #   for debugging purposes. Default is false.
      #
      # @example Initialize with no filtering
      #   builder = FormattingComponents::PayloadBuilder.new
      #   # No keys are filtered; all keys appear in the output
      #
      # @example Initialize with filtering and removal
      #   builder = FormattingComponents::PayloadBuilder.new(
      #     filtered_keys: ['password', 'api_key', 'token'],
      #     keep_filtered_keys: false
      #   )
      #   # Keys named 'password', 'api_key', or 'token' are removed from the output
      #
      # @example Initialize with filtering and debug output
      #   builder = FormattingComponents::PayloadBuilder.new(
      #     filtered_keys: ['password', 'api_key', 'secret'],
      #     keep_filtered_keys: true
      #   )
      #   # Matching keys will be moved to :_filtered hash for debugging purposes
      #   # Useful when you want to remove sensitive data from logs but need to audit what was filtered
      #
      def initialize(filtered_keys: nil, keep_filtered_keys: false)
        @filtered_keys = Array(filtered_keys).map(&:to_s).freeze
        @keep_filtered_keys = keep_filtered_keys
      end

      # Builds and serialises the final JSON log payload.
      #
      # Assembles payload by:
      # 1. Starting with timestamp
      # 2. Enriching message with controller/action context (if present)
      # 3. Formatting and appending request_time to message string (if present)
      # 4. Merging request context from thread storage
      # 5. Merging formatted message
      # 6. Applying key filtering if configured (removal or debug collection)
      # 7. Reordering fields (ts, level first)
      # 8. Serialising to JSON with trailing newline
      #
      # @param timestamp [String] ISO 8601 formatted timestamp with milliseconds
      # @param message [Hash] Processed and formatted message hash with symbolized keys.
      #   May include: :level, :message, :controller, :action, :request_time, etc.
      #
      # @return [String] JSON-formatted log line with trailing newline
      #
      # @raise [JSON::GeneratorError] If payload contains circular references
      #
      # @example Build payload with filtering enabled (removal)
      #   builder = FormattingComponents::PayloadBuilder.new(
      #     filtered_keys: ['password', 'api_key'],
      #     keep_filtered_keys: false
      #   )
      #   message = { level: "INFO", message: "login attempt", password: "secret123", api_key: "xyz789" }
      #   builder.build(timestamp: "2026-03-04T10:30:00.000Z", message: message)
      #   # => "{\"ts\":\"2026-03-04T10:30:00.000Z\",\"level\":\"INFO\",\"message\":\"login attempt\"}\n"
      #   # Note: password and api_key are completely removed when keep_filtered_keys is false
      #
      # @example Build payload with filtering and debug output
      #   builder = FormattingComponents::PayloadBuilder.new(
      #     filtered_keys: ['password', 'api_key'],
      #     keep_filtered_keys: true
      #   )
      #   message = { level: "INFO", message: "login attempt", password: "secret123", api_key: "xyz789" }
      #   builder.build(timestamp: "2026-03-04T10:30:00.000Z", message: message)
      #   # => "{\"ts\":\"2026-03-04T10:30:00.000Z\",\"level\":\"INFO\",\"message\":\"login attempt\",
      #   #     \"_filtered\":{\"password\":\"secret123\",\"api_key\":\"xyz789\"}}\n"
      #   # Filtered keys are preserved under :_filtered for debugging/auditing purposes
      #
      def build(timestamp:, message:)
        # Start building the payload with the timestamp
        payload = { ts: timestamp }

        # Enrich message with controller/action context when present
        enriched_message = enrich_message_with_request_details(message)

        # Merge request context from thread storage and processed message
        payload.merge!(FormattingComponents::RequestContext.collect)
        payload.merge!(enriched_message.sort.to_h.compact)

        # Apply key filtering if configured
        payload = apply_filtering(payload) if @filtered_keys.any?

        # Reorder so ts, level and message come first after all processing is done
        final_payload = reorder_payload(payload)

        # Convert to JSON and add newline
        serialise_payload(final_payload)
      rescue JSON::NestingError
        raise JSON::GeneratorError, 'circular reference detected'
      end

      private

      # Enriches message with controller/action context and request timing information.
      #
      # If message contains controller or action fields, delegates to MessageComposer
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
          enriched[:message] = FormattingComponents::MessageComposer.new.include_component_details(enriched)
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

      # Applies recursive key filtering to the payload based on configuration.
      #
      # Traverses all nested hashes and arrays, removing any keys that match the
      # configured filter patterns. Filtered values are either discarded or
      # collected under :_filtered depending on keep_filtered_keys.
      #
      # When keep_filtered_keys is true, each removed value is recorded using a
      # dot-separated path reflecting its location in the original structure
      # (for example, "user.password" or "metadata.0.token").
      #
      # @param payload [Hash] The assembled payload to filter
      # @return [Hash] A filtered copy of the payload, with :_filtered appended
      #   when keep_filtered_keys is true and matching keys were found
      #
      def apply_filtering(payload)
        filtered_items = {}
        filtered_payload = prune_nested_values(payload.dup, filtered_items, [])
        filtered_payload[:_filtered] = filtered_items if @keep_filtered_keys && filtered_items.any?
        filtered_payload
      end

      # Dispatches recursive filtering based on the type of the current value.
      #
      # Acts as the recursive entry point for the filtering traversal, delegating
      # to the appropriate handler for hashes, arrays, and scalar values.
      #
      # @param value [Hash, Array, Object] The current node in the payload tree
      # @param filtered_items [Hash] Accumulator for removed key/value pairs,
      #   keyed by dot-separated path strings
      # @param path [Array<String, Symbol, Integer>] The traversal path from root
      #   to the current node, used to build :_filtered path keys
      # @return [Hash, Array, Object] A filtered copy of the current node
      #
      def prune_nested_values(value, filtered_items, path)
        case value
        when Hash
          prune_nested_hashes(value, filtered_items, path)
        when Array
          prune_nested_arrays(value, filtered_items, path)
        else
          value
        end
      end

      # Rebuilds a hash, omitting keys that match the configured filter patterns.
      #
      # Iterates each key/value pair, either discarding the pair or recursing into
      # the value when not filtered. Matching keys are recorded in filtered_items
      # when keep_filtered_keys is enabled.
      #
      # @param value [Hash] The hash to filter
      # @param filtered_items [Hash] Accumulator for removed key/value pairs
      # @param path [Array<String, Symbol, Integer>] Current traversal path
      # @return [Hash] A new hash with matching keys removed
      #
      def prune_nested_hashes(value, filtered_items, path)
        value.each_with_object({}) do |(key, child), acc|
          key_path = path + [key]
          if matches_filter?(key)
            filtered_items[key_path.join('.')] = child if @keep_filtered_keys
          else
            acc[key] = prune_nested_values(child, filtered_items, key_path)
          end
        end
      end

      # Maps over an array, recursively filtering each element.
      #
      # Array indices are appended to the traversal path so that :_filtered path
      # keys remain unambiguous (for example, "metadata.0.token").
      #
      # @param value [Array] The array to traverse
      # @param filtered_items [Hash] Accumulator for removed key/value pairs
      # @param path [Array<String, Symbol, Integer>] Current traversal path
      # @return [Array] A new array with each element recursively filtered
      #
      def prune_nested_arrays(value, filtered_items, path)
        value.each_with_index.map do |child, index|
          prune_nested_values(child, filtered_items, path + [index])
        end
      end

      # Checks if a key matches any of the filter patterns.
      #
      # Performs exact string matching against filter patterns (all converted to strings).
      #
      # @param key [Symbol, String] The key to check
      # @return [Boolean] True if key matches any filter pattern
      #
      def matches_filter?(key)
        key_str = key.to_s
        @filtered_keys.any? { |pattern| pattern == key_str }
      end

      # Reorders payload to ensure timestamp and level appear first.
      #
      # Operational logs typically scan ts and level first for filtering/analysis,
      # so these fields are positioned at the beginning of the JSON output for
      # improved readability and parsing efficiency.
      #
      # @param payload [Hash] Unordered payload hash
      # @return [Hash] Reordered payload with ts, level, and message first and remaining fields sorted
      # alphabetically after except :_filtered which is kept at the end
      #
      def reorder_payload(payload)
        reordered = {
          ts: payload[:ts],
          level: payload[:level],
          message: payload[:message]
        }

        rest = payload.except(:ts, :level, :message, :_filtered).sort.to_h
        filtered = payload.key?(:_filtered) ? { _filtered: payload[:_filtered] } : {}

        reordered.merge(rest).merge(filtered)
      end

      # Serialises payload to JSON with trailing newline.
      #
      # @param payload [Hash] Payload to serialise
      # @return [String] JSON string with trailing newline
      #
      def serialise_payload(payload)
        "#{payload.to_json}\n"
      end
    end
  end
end
