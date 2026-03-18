# frozen_string_literal: true

module JsonRailsLogger
  # Middleware that captures and stores HTTP request IDs for correlation in JSON logs.
  #
  # Extracts the request ID from HTTP headers and stores it in thread-local storage,
  # making it available to the logger for inclusion in every log entry during request
  # processing. This enables request tracing across multiple log entries and microservices.
  #
  # Request IDs are sourced from:
  # - Production: HTTP `X-Request-ID` header (set by load balancers or clients)
  # - Development: Rails' `action_dispatch.request_id` (generated per request)
  #
  # The stored request ID is automatically cleared after request completion to prevent
  # data leaking in thread pool environments.
  #
  # @example How it integrates
  #   # Automatically inserted by Railtie after ActionDispatch::RequestId
  #   # No manual configuration needed
  #
  class RequestIdMiddleware
    # Initialises the middleware with the Rails application.
    #
    # @param app [Object] The next middleware in the Rails middleware stack
    def initialize(app)
      @app = app
    end

    # Handles each HTTP request by capturing and storing the request ID.
    #
    # Extracts the request ID from HTTP headers (X-Request-ID in production,
    # action_dispatch.request_id in development) and stores it in thread-local
    # storage for access during request processing. The request ID is automatically
    # cleared in the ensure block after request completion to prevent data leaking
    # in thread pool environments.
    #
    # @param env [Hash] The Rack environment for the current request
    # @return [Array] The response from the next middleware in the stack
    def call(env)
      request_id = env['HTTP_X_REQUEST_ID']
      request_id = env['action_dispatch.request_id'] if Rails.env.development?
      Thread.current[JsonRailsLogger::REQUEST_ID] = request_id
      @app.call(env)
    ensure
      Thread.current[JsonRailsLogger::REQUEST_ID] = nil
    end
  end
end
