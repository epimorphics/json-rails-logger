# frozen_string_literal: true

module JsonRailsLogger
  # Raised when JsonRailsLogger fails to initialise properly during Rails setup.
  #
  # This exception is thrown when the logger cannot be configured as the Rails
  # application logger, typically due to missing or invalid configuration.
  # Handlers should ensure JsonRailsLogger is properly configured in the Rails
  # environment config file before the application boots.
  #
  # @example Configuration to avoid this error
  #   # config/environments/production.rb
  #   config.logger = JsonRailsLogger::Logger.new(STDOUT)
  #
  class LoggerSetupError < StandardError
  end
end
