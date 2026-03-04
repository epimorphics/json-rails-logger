# frozen_string_literal: true

module JsonRailsLogger
  module FormattingComponents
    # Composes enriched log messages by incorporating application-specific context.
    #
    # This class is responsible for building human-readable log messages that include
    # application-specific information extracted from structured log data. It provides
    # clear, contextual messages for operational monitoring in Epimorphics operational
    # systems, ensuring log output can be easily interpreted by operations teams.
    #
    # @example Basic usage
    #   composer = RequestMessageComposer.new
    #   msg_data = { controller: 'DatasetsController', action: 'index' }
    #   result = composer.include_component_details(msg_data)
    #   # => "Datasets index request complete"
    #
    # @example With request URI
    #   msg_data = {
    #     controller: 'DatasetsController',
    #     action: 'show',
    #     request_uri: '/datasets/123'
    #   }
    #   result = composer.include_component_details(msg_data)
    #   # => "Datasets show request complete to /datasets/123"
    class RequestMessageComposer
      # Includes request context information in the log message.
      #
      # Extracts controller, action, and request URI from the message data and
      # composes a human-readable message describing the request. If controller
      # or action are missing, returns the original message unchanged.
      #
      # @param msg [Hash] The message hash containing request metadata
      # @option msg [String] :controller Controller class name (e.g., 'DatasetsController')
      # @option msg [String] :action Action method name (e.g., 'index', 'show')
      # @option msg [String] :request_uri Full request URI path
      # @option msg [String] :message Original message (returned if controller/action missing)
      #
      # @return [String] Enriched message with request context
      #
      # @example Standard request
      #   composer.include_component_details(
      #     controller: 'ArticlesController',
      #     action: 'create'
      #   )
      #   # => "Articles create request complete"
      #
      # @example With URI
      #   composer.include_component_details(
      #     controller: 'UsersController',
      #     action: 'update',
      #     request_uri: '/users/42'
      #   )
      #   # => "Users update request complete to /users/42"
      def include_component_details(msg)
        action = msg['action'] || msg[:action]
        controller = msg['controller'] || msg[:controller]
        request_uri = msg['request_uri'] || msg[:request_uri]

        tmp_msg = build_controller_action_message(action, controller, msg[:message]) || ''
        append_request_uri(tmp_msg, request_uri)
      end

      private

      # Builds a message from controller and action names.
      #
      # Strips 'Controller' suffix and module namespacing from the controller name,
      # then combines it with the action to create a standardised message format.
      #
      # @param action [String, nil] The action method name
      # @param controller [String, nil] The controller class name
      # @param original_message [String, nil] Fallback message if action/controller blank
      #
      # @return [String, nil] Formatted message or original message
      #
      # @example
      #   build_controller_action_message('index', 'Admin::DatasetsController', nil)
      #   # => "Datasets index request complete"
      def build_controller_action_message(action, controller, original_message)
        return original_message if action.blank? || controller.blank?

        controller_name = controller.to_s.gsub('Controller', '').split('::').last
        "#{controller_name} #{action} request complete"
      end

      # Appends request URI to the message when available.
      #
      # @param message [String] The base message to enhance
      # @param request_uri [String, nil] The URI to append
      #
      # @return [String] Message with appended URI, or original message if URI blank
      #
      # @example
      #   append_request_uri("Articles show request complete", "/articles/42")
      #   # => "Articles show request complete to /articles/42"
      def append_request_uri(message, request_uri)
        return message if request_uri.blank?

        # If request_uri is present, append it to the message for better context
        message + format(' to %s', request_uri)
      end
    end
  end
end
