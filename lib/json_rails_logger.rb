# frozen_string_literal: true

require 'lograge'
require 'json_rails_logger/railtie' if defined?(Rails)

require 'json_rails_logger/error.rb'
require 'json_rails_logger/logger.rb'
require 'json_rails_logger/version.rb'

require 'json_rails_logger/formatter/json.rb'

# A custom rails logger that outputs json instead of raw text
module JsonRailsLogger
  def self.setup(app); end

  def self.enabled?(app); end
end
