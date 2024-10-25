# frozen_string_literal: true

module JsonRailsLogger
  ACCEPT = :accept
  BACKTRACE = :backtrace
  BODY = :body
  DURATION = :duration
  EXCEPTION = :exception
  GATEWAY = :gateway
  HTTP_HOST = :http_host
  HTTP_ORIGIN = :http_origin
  HTTP_REFERER = :http_referer
  MESSAGE = :message
  METHOD = :method
  QUERY_STRING = :query_string
  REMOTE_ADDR = :remote_addr
  REQUEST_ID = :request_id
  REQUEST_PARAMS = :request_params
  REQUEST_PATH = :request_path
  REQUEST_STATUS = :request_status
  REQUEST_URI = :request_uri
  SERVER_NAME = :server_name
  SERVER_PORT = :server_port
  SERVER_PROTOCOL = :server_protocol
  SERVER_SOFTWARE = :server_software
  STATUS = :status
  USER_AGENT = :user_agent
  # * THE FOLLOWING ARE NOT CURRENTLY USED BUT AVAILABLE FOR USE * #
  # ACTION = :action
  # AUTH = :auth
  # CONTROLLER = :controller
  # FORWARDED_FOR = :forwarded_for
  # HTTP_ACCEPT_CHARSET = :http_accept_charset
  # HTTP_ACCEPT_ENCODING = :http_accept_encoding
  # HTTP_ACCEPT_LANGUAGE = :http_accept_language
  # HTTP_CACHE_CONTROL = :http_cache_control
  # HTTP_COOKIE = :http_cookie
  # HTTP_CONNECTION = :http_connection
  # HTTP_DNT = :http_dnt
  # HTTP_UPGRADE_INSECURE_REQUESTS = :http_upgrade_insecure_requests
  # HTTP_VERSION = :http_version
  # HTTP_X_REQUEST_ID = :http_x_request_id
  # IP = :ip
  # REQUEST_METHOD = :request_method
end
