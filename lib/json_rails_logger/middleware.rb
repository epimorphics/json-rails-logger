# frozen_string_literal: true

require_relative 'constants'

module JsonRailsLogger
  # Middleware that saves the request_id into a constant
  # and clears it after usage in the formatter
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request_id = env['action_dispatch.request_id']
      Thread.current[JsonRailsLogger::REQUEST_ID] = request_id
      @app.call(env)
    ensure
      Thread.current[JsonRailsLogger::REQUEST_ID] = nil
    end
  end
end
