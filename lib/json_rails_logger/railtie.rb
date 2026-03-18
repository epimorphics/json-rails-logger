# frozen_string_literal: true

module JsonRailsLogger
  # Configures Rails integration for JSON logging through Lograge.
  #
  # Automatically executes during Rails initialisation to:
  # 1. Configure Lograge to output JSON format instead of plain text
  # 2. Disable Rails' default colourised logging output
  # 3. Include exception metadata in JSON payload
  # 4. Insert RequestIdMiddleware into the middleware stack (after ActionDispatch::RequestId)
  # 5. Set up thread-local request ID storage for correlation across log entries
  #
  # This Railtie is automatically loaded when the gem is required; no explicit
  # configuration is needed beyond adding the gem to Gemfile and setting
  # `config.logger = JsonRailsLogger::Logger.new(STDOUT)` in your environment config.
  #
  # @see JsonRailsLogger.setup
  # @see Lograge::Formatters::Json
  class Railtie < Rails::Railtie
    config.colorize_logging = false
    config.lograge.keep_original_rails_log = false
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.custom_options = lambda do |event|
      {
        exception: event.payload[:exception],
        exception_object: event.payload[:exception_object]
      }
    end

    config.after_initialize do |app|
      if JsonRailsLogger.enabled?(app)
        JsonRailsLogger.setup(app)
        Lograge.setup(app)
      end
    end

    initializer 'railtie.configure_rails_initialization' do |app|
      app.middleware.insert_after(ActionDispatch::RequestId,
                                  JsonRailsLogger::RequestIdMiddleware)
    end
  end
end
