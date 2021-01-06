# frozen_string_literal: true

# A custom rails logger that outputs json instead of raw text
module JsonRailsLogger
  def self.setup(app); end

  def self.enabled?(app); end
end
