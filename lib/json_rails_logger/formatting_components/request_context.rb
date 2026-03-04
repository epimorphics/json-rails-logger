# frozen_string_literal: true

module JsonRailsLogger
  # Namespace for formatting components used to deconstruct JSON formatter logic
  module FormattingComponents
    # Centralises retrieval of request-scoped metadata from thread-local storage for log enrichment.
    #
    # Collects request identifiers, query strings, and request parameters stored by Rails
    # middleware (RequestIdMiddleware) during request processing within Epimorphics applications.
    # Returns unified hash suitable for merging into JSON log payload, ensuring consistent
    # request context across all log entries within the same request lifecycle.
    #
    # Thread-local storage keys accessed:
    # - JsonRailsLogger::REQUEST_ID (set by RequestIdMiddleware)
    # - JsonRailsLogger::QUERY_STRING (set by Rails/Rack middleware)
    # - JsonRailsLogger::REQUEST_PARAMS (set by Rails/Rack middleware, with PARAMS fallback)
    #
    # @example Collect request context with all fields present
    #   Thread.current[JsonRailsLogger::REQUEST_ID] = "abc-123"
    #   Thread.current[JsonRailsLogger::QUERY_STRING] = "foo=bar"
    #   Thread.current[JsonRailsLogger::REQUEST_PARAMS] = { user_id: 42 }
    #   RequestContext.collect
    #   # => { request_id: "abc-123", query_string: "foo=bar", request_params: { user_id: 42 } }
    #
    # @example Collect context with only request_id available
    #   Thread.current[JsonRailsLogger::REQUEST_ID] = "xyz-789"
    #   RequestContext.collect
    #   # => { request_id: "xyz-789" }
    #
    # @example No context available
    #   RequestContext.collect
    #   # => {}
    #
    class RequestContext
      # Collects all available request context metadata from thread-local storage.
      #
      # Retrieves request_id, query_string, and request_params from Thread.current
      # storage if present. Returns empty hash if no context is available (e.g. during
      # non-request logging or when middleware hasn't set context).
      #
      # @return [Hash] Hash containing available request context fields.
      #   Keys: :request_id, :query_string, :request_params (only keys with values present)
      #
      def self.collect
        context = {}
        context.merge!(request_id)
        context.merge!(query_string) unless query_string.nil?
        context.merge!(request_params) unless request_params.nil?
        context
      end

      # Extract the request ID from thread storage.
      #
      # @return [Hash] Hash with :request_id key if present, otherwise empty hash
      # @api private
      #
      def self.request_id
        request_id = Thread.current[JsonRailsLogger::REQUEST_ID]
        request_id ? { request_id: request_id } : {}
      end

      # Extract the query string from thread storage.
      #
      # @return [Hash, nil] Hash with :query_string key if present and non-empty, otherwise nil
      # @api private
      #
      def self.query_string
        query_string = Thread.current[JsonRailsLogger::QUERY_STRING]
        { query_string: query_string } if query_string.present?
      end

      # Extract the request parameters from thread storage.
      #
      # Checks REQUEST_PARAMS first, falls back to PARAMS alias if not found.
      #
      # @return [Hash, nil] Hash with :request_params key if present and non-empty, otherwise nil
      # @api private
      #
      def self.request_params
        request_params = Thread.current[JsonRailsLogger::REQUEST_PARAMS]
        request_params ||= Thread.current[JsonRailsLogger::PARAMS]
        { request_params: request_params } if request_params.present?
      end

      private_class_method :request_id, :query_string, :request_params
    end
  end
end
