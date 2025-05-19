# frozen_string_literal: true

module JsonRailsLogger
  # This class is used to configure and setup lograge, as well as our gem
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
