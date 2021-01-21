# frozen_string_literal: true

require 'lograge'
require './lib/json_rails_logger/railtie' if defined?(Rails)

require './lib/json_rails_logger/error.rb'
require './lib/json_rails_logger/logger.rb'
require './lib/json_rails_logger/version.rb'

require './lib/json_rails_logger/formatter/json.rb'

# A custom rails logger that outputs json instead of raw text
module JsonRailsLogger
  def self.setup(app)
    unless enabled?(app)
      raise JsonRailsLogger::LoggerSetupError,
            'Please configure rails logger to use JsonRailsLogger'
    end
  end

  def self.enabled?(app)
    !app.config.logger.nil? &&
      app.config.logger.class == JsonRailsLogger::Logger
  end
end
