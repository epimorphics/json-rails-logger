# frozen_string_literal: true

module JsonRailsLogger
  BACKTRACE = :backtrace
  DURATION = :duration
  EXCEPTION = :exception
  MESSAGE = :message
  METHOD = :method
  PATH = :request_path # Alias for REQUEST_PATH
  QUERY_STRING = :query_string
  REQUEST_ID = :request_id
  REQUEST_PARAMS = :request_params
  REQUEST_PATH = :request_path
  REQUEST_STATUS = :request_status
  REQUEST_URI = :request_uri
  STATUS = :status
  # * THE FOLLOWING ARE NOT CURRENTLY USED BUT AVAILABLE FOR USE * #
  # ACCEPT = :accept
  # ACTION = :action
  # AUTH = :auth
  # BODY = :body
  # CONTROLLER = :controller
  # FORWARDED_FOR = :forwarded_for
  # GATEWAY = :gateway
  # HTTP_ACCEPT_CHARSET = :http_accept_charset
  # HTTP_ACCEPT_ENCODING = :http_accept_encoding
  # HTTP_ACCEPT_LANGUAGE = :http_accept_language
  # HTTP_CACHE_CONTROL = :http_cache_control
  # HTTP_COOKIE = :http_cookie
  # HTTP_CONNECTION = :http_connection
  # HTTP_DNT = :http_dnt
  # HTTP_HOST = :http_host
  # HTTP_ORIGIN = :http_origin
  # HTTP_REFERER = :http_referer
  # HTTP_UPGRADE_INSECURE_REQUESTS = :http_upgrade_insecure_requests
  # HTTP_VERSION = :http_version
  # HTTP_X_REQUEST_ID = :http_x_request_id
  # IP = :ip
  # REMOTE_ADDR = :remote_addr
  # REQUEST_METHOD = :request_method
  # SERVER_NAME = :server_name
  # SERVER_PORT = :server_port
  # SERVER_PROTOCOL = :server_protocol
  # SERVER_SOFTWARE = :server_software
  # USER_AGENT = :user_agent
end
