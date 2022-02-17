# frozen_string_literal: true

require 'lograge'

require_relative 'json_rails_logger/railtie'
require_relative 'json_rails_logger/constants'
require_relative 'json_rails_logger/request_id_middleware'
require_relative 'json_rails_logger/json_formatter'
require_relative 'json_rails_logger/error'
require_relative 'json_rails_logger/logger'
require_relative 'json_rails_logger/version'

# A custom rails logger that outputs json instead of raw text
module JsonRailsLogger
  def self.setup(app)
    return if enabled?(app)

    raise JsonRailsLogger::LoggerSetupError,
          'Please configure rails logger to use JsonRailsLogger'
  end

  def self.enabled?(app)
    !app.config.logger.nil? &&
      app.config.logger.instance_of?(JsonRailsLogger::Logger)
  end
end
