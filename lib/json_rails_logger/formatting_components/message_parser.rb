# frozen_string_literal: true

module JsonRailsLogger
  # Namespace for formatting components used to deconstruct JSON formatter logic
  module FormattingComponents
    # Parses raw log message input to detect and extract operational context from log output strings.
    #
    # This parser handles multiple message formats used within Epimorphics logging systems:
    # detects status codes (e.g. "Status 200"), HTTP request lines (e.g. "GET http://..."),
    # user-agent headers, and plain text messages. When a message matches a known pattern,
    # extracts structured metadata (HTTP method, request path, status code, user-agent);
    # otherwise normalises and cleans the string for safe JSON serialisation.
    #
    # Used by JsonFormatter to deconstruct raw_msg input before adding to log payload,
    # enabling cleaner separation of parsing logic from formatting orchestration.
    #
    # @example Parse a status code message
    #   parser = FormattingComponents::MessageParser.new
    #   parser.parse("Status 200")
    #   # => { status: 200 }
    #
    # @example Parse a request type message
    #   parser.parse("GET http://example.com/api/users")
    #   # => { method: "GET", path: "/api/users" }
    #
    # @example Parse plain text with unprintable characters
    #   parser.parse("Hello\e[31m World")  # with ANSI colour code
    #   # => { message: "Hello World" }
    #
    class MessageParser
      ## HTTP request methods to check for in message strings
      REQUEST_METHODS = %w[GET POST PUT DELETE PATCH].freeze

      # Parses a raw log message and returns structured data or cleaned message string.
      #
      # Orchestrates detection of common message patterns in order:
      # 1. JSON strings (attempt parse)
      # 2. Status codes ("Status NNN")
      # 3. Request types ("METHOD http://...")
      # 4. User-agent headers ("User-Agent: ... Accept: ...")
      # 5. Plain text (clean ANSI codes, squish whitespace)
      #
      # @param raw_msg [String, Hash, Object] The log message to parse.
      #   Strings are checked for patterns; hashes are returned as-is; other objects
      #   are converted to string via to_s before parsing.
      #
      # @return [Hash] Parsed message or cleaned string wrapped in :message key.
      #   Examples: { status: 200 }, { method: "GET", path: "..." }, { message: "..." }
      #
      def parse(raw_msg)
        # If the message is nil, return an empty hash
        return {} if raw_msg.nil?

        # Otherwise, normalise the message
        msg = normalise_message(raw_msg)

        return msg unless msg.is_a?(String)
        return status_message(msg) if status_message?(msg)
        return request_type(msg) if request_type?(msg)
        return user_agent_message(msg) if user_agent_message?(msg)

        # Clean up the message if it contains special characters
        msg = remove_unprintable_characters(msg)

        # squish is better than strip as it still returns the string, but first
        # removing all whitespace on both ends of the string, and then changing
        # remaining consecutive whitespace groups into one space each. strip only
        # removes white spaces only at the leading and trailing ends.
        { message: msg.squish }
      end

      private

      # Attempts to parse raw_msg as JSON, returns string if parsing fails.
      #
      # @param raw_msg [String, Hash, Object] The value to parse
      # @return [String, Hash] Parsed JSON as hash, or original string if parse fails
      #
      def normalise_message(raw_msg)
        return raw_msg unless raw_msg.is_a?(String)

        JSON.parse(raw_msg)
      rescue JSON::ParserError
        raw_msg
      end

      # Detects whether a string contains a status code pattern ("Status NNN").
      #
      # @param msg [String] Message to check
      # @return [Boolean] true if message matches /status [0-9]+/ pattern (case-insensitive)
      #
      def status_message?(msg)
        msg.is_a?(String) &&
          msg.downcase.match(/status [0-9]+/)
      end

      # Extracts HTTP status code from a message string.
      #
      # Handles both "Status NNN" and "response: Status NNN" formats. Returns
      # the extracted code as an integer.
      #
      # @param msg [String] Message containing status code
      # @return [Hash] Hash with :status key and integer code value
      #
      def status_message(msg)
        split_status = msg.split
        is_status = split_status[0] == 'response:'
        code = split_status[is_status ? 2 : 1]

        status = code.to_i

        { status: status }
      end

      # Detects whether a string contains an HTTP request type pattern.
      #
      # Checks for patterns like "GET http://..." or "POST https://..." using
      # the REQUEST_METHODS list (GET, POST, PUT, DELETE, PATCH).
      #
      # @param msg [String] Message to check
      # @return [Boolean] true if message contains METHOD followed by http(s) URL
      #
      def request_type?(msg)
        msg.is_a?(String) &&
          REQUEST_METHODS.any? { |method| msg.match(/#{method} http\S+/) }
      end

      # Extracts HTTP method and request path from a message string.
      #
      # Handles both "METHOD path" and "request: METHOD path" formats, extracting
      # the HTTP method (GET, POST, etc.) and the URL path component.
      #
      # @param msg [String] Message containing request method and path
      # @return [Hash] Hash with :method and :path keys
      #
      def request_type(msg)
        split_type = msg.split
        is_request = split_type[0] == 'request:'
        method = split_type[is_request ? 1 : 0]
        path = split_type[is_request ? 2 : 1]
        { method: method, path: path }
      end

      # Detects whether a string contains a user-agent header pattern.
      #
      # Checks for format: "User-Agent: \"...\"\nAccept: \"...\"" using case-insensitive
      # matching and multiline regex.
      #
      # @param msg [String] Message to check
      # @return [Boolean] true if message contains User-Agent and Accept header pattern
      #
      def user_agent_message?(msg)
        msg.is_a?(String) &&
          msg.downcase.match(/user-agent: .[\S\s]+accept: .+/m)
      end

      # Extracts user-agent and accept fields from a message string.
      #
      # Parses a two-line message format containing User-Agent and Accept headers,
      # extracting the quoted values from each line.
      #
      # Example input:
      #   "User-Agent: \"Mozilla/5.0\"\nAccept: \"application/json\""
      #
      # @param msg [String] Message containing User-Agent and Accept headers
      # @return [Hash] Hash with :user_agent and :accept keys
      #
      def user_agent_message(msg)
        splitted_msg = msg.split("\n")
        user_agent = splitted_msg[0]&.split('"')&.at(1)
        accept = splitted_msg[1]&.split('"')&.at(1)

        { user_agent: user_agent, accept: accept }
      end

      # Removes ANSI escape codes, non-printable characters, and non-ASCII from a message string.
      #
      # Performs sequential cleaning:
      # 1. Strips ANSI colour/style codes (e.g. \e[31m)
      # 2. Removes all non-printable characters
      # 3. Removes all non-ASCII characters (outside 0x00-0x7F range)
      #
      # Ensures clean UTF-8 compatible output safe for JSON serialisation.
      #
      # @param msg [String] Message to clean
      # @return [String] Cleaned message with unprintable characters removed
      #
      def remove_unprintable_characters(msg)
        # Remove ANSI escape codes
        msg = msg.gsub(/\e\[[0-9;]*m/, '') if msg.match?(/\e\[[0-9;]*m/)
        # Remove all non-printable characters
        msg = msg.gsub(/[^[:print:]]/, '') if msg.match?(/[^[:print:]]/)
        # Remove all non-ASCII characters
        msg = msg.gsub(/[^\x00-\x7F]/, '') if msg.match?(/[^\x00-\x7F]/)

        msg
      end
    end
  end
end
