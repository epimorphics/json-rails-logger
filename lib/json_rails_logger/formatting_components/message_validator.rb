# frozen_string_literal: true

module JsonRailsLogger
  # Namespace for formatting components used to decompose JSON formatter logic
  module FormattingComponents
    # Validates and normalises message data structures for structured logging.
    #
    # Ensures all required logging fields are present in message hashes (with nil defaults),
    # detects and normalises timing values, and handles edge cases (single-key message hashes,
    # missing fields). Provides schema conformance guarantees before message enrichment and
    # payload assembly in Epimorphics operational logging systems, maintaining data integrity
    # across the logging pipeline.
    #
    # @example Validate structured message
    #   validator = FormattingComponents::MessageValidator.new
    #   msg = { message: "User created", controller: "UsersController" }
    #   validator.validate(msg)
    #   # => Hash with all REQUIRED_KEYS present (nil-filled where missing)
    #
    # @example Validate message with timing
    #   msg = { message: "Request processed", request_time: 125.5, duration: 100.0 }
    #   validator.validate(msg)
    #   # => { ..., request_time: 126, duration: 100.0, ... }
    #
    # @example Single-key message hash (pass-through)
    #   msg = { message: "Simple message" }
    #   validator.validate(msg)
    #   # => { message: "Simple message" } (unchanged)
    #
    class MessageValidator
      # Validates and normalises a message hash.
      #
      # If message is a single-key hash containing only a :message field with string value,
      # returns as-is (treated as pre-formatted message). Otherwise ensures all required keys
      # from JsonFormatter::REQUIRED_KEYS are present (nil-filled), and normalises timing
      # fields if present (converts request_time floats to millisecond integers).
      #
      # @param msg [Hash] Message hash to validate
      # @return [Hash] Validated message with all required keys present
      #
      def validate(msg)
        return msg if string_message_field?(msg)
        return {} unless msg.is_a?(Enumerable)

        msg = ensure_required_keys(msg)
        msg = normalise_timing(msg) if includes_timing?(msg)

        msg
      end

      private

      # Checks if message is a single-key hash with :message containing a string.
      #
      # Single-key message hashes are treated as pre-formatted and returned as-is,
      # skipping validation to preserve their original form.
      #
      # @param msg [Hash] Message to check
      # @return [Boolean] true if message is single-key hash with string :message value
      #
      def string_message_field?(msg)
        msg.is_a?(Hash) &&
          msg.length == 1 &&
          msg.fetch(:message, nil).is_a?(String)
      end

      # Ensures all required logging keys are present in message hash.
      #
      # Adds missing keys from JsonFormatter::REQUIRED_KEYS with nil values,
      # supporting both symbol and string key naming conventions.
      #
      # @param msg [Hash] Message hash to check
      # @return [Hash] Message with all required keys present
      #
      def ensure_required_keys(msg)
        msg = msg.to_h if msg.respond_to?(:to_h)
        JsonFormatter::EXPECTED_KEYS.each do |key|
          key_sym = key.to_sym
          msg[key_sym] = msg[key_sym] || msg[key.to_s] || nil unless msg.key?(key_sym)
        end
        msg
      end

      # Detects whether message contains timing-related fields.
      #
      # Checks for presence of :duration, :request_time (as symbol or string).
      #
      # @param msg [Hash] Message to check
      # @return [Boolean] true if message contains timing fields
      #
      def includes_timing?(msg)
        msg.key?('duration') ||
          msg.key?(:duration) ||
          msg.key?('request_time') ||
          msg.key?(:request_time)
      end

      # Normalises timing values from microseconds/floats to milliseconds.
      #
      # If request_time is a float, converts it to integer milliseconds via rounding.
      # If request_time is nil but duration (float) is present, derives request_time
      # from duration. Duration is already in milliseconds from Lograge, so preserved as-is.
      #
      # @param msg [Hash] Message containing timing fields
      # @return [Hash] Message with normalised timing values
      #
      def normalise_timing(msg)
        result = msg.to_h { |k, v| [k, v] }

        if result[:request_time].nil? && result[:duration].is_a?(Float)
          result[:request_time] = result[:duration].round(0)
        elsif result[:request_time].is_a?(Float)
          result[:request_time] = result[:request_time].round(0)
        end

        result
      end
    end
  end
end
