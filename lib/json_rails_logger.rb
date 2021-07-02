# frozen_string_literal: true

require 'logger'
require 'json'
require 'rails'
require 'lograge'

require_relative 'json_rails_logger/railtie' if defined?(Rails)

require_relative 'json_rails_logger/json_formatter.rb'
require_relative 'json_rails_logger/error.rb'
require_relative 'json_rails_logger/logger.rb'

# A custom rails logger that outputs json instead of raw text
module JsonRailsLogger
  def self.setup(app)
    return if enabled?(app)

    raise JsonRailsLogger::LoggerSetupError,
          'Please configure rails logger to use JsonRailsLogger'
  end

  def self.enabled?(app)
    !app.config.logger.nil? &&
      app.config.logger.class == JsonRailsLogger::Logger
  end
end
