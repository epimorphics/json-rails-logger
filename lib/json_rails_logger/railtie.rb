# frozen_string_literal: true

require_relative 'middleware'

module JsonRailsLogger
  # This class is used to configure and setup lograge, as well as our gem
  class Railtie < Rails::Railtie
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.custom_options = lambda do |event|
      {
        exception: event.payload[:exception],
        exception_object: event.payload[:exception_object]
      }
    end

    config.after_initialize do |app|
      JsonRailsLogger.setup(app) if JsonRailsLogger.enabled?(app)
      Lograge.setup(app) if JsonRailsLogger.enabled?(app)
    end

    initializer 'railtie.configure_rails_initialization' do |app|
      app.middleware.insert_after ActionDispatch::RequestId,
                                  JsonRailsLogger::Middleware
    end
  end
end
