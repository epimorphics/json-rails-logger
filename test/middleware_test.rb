# frozen_string_literal: true

require './test/test_helper'

describe 'JsonRailsLogger::RequestIdMiddleware' do
  # Tests for middleware that manages request_id storage in thread-local context.
  # The middleware extracts request_id from different sources depending on Rails environment:
  # - Production: HTTP_X_REQUEST_ID header
  # - Development: action_dispatch.request_id (Rails' built-in request ID)
  #
  # Key testing challenge: the middleware's ensure block clears the thread-local value
  # after the app executes, so we use capturing_app lambdas to record the value while
  # the middleware executes.

  let(:app) { ->(_env) { [200, {}, ['OK']] } }
  let(:middleware) { JsonRailsLogger::RequestIdMiddleware.new(app) }

  # Helper to mock Rails.env for testing different environments.
  # We set up a mock Rails constant with an env object that responds to development?
  # Returns false for production tests, true for development tests.
  def setup_rails_env(development:)
    mock_env = Object.new
    mock_env.define_singleton_method(:development?) { development }
    mock_rails = Class.new(Object)
    mock_rails.define_singleton_method(:env) { mock_env }
    Object.const_set('Rails', mock_rails)
  end

  # Cleanup: Remove the mocked REQUEST_ID and Rails constant after each test.
  # This prevents cross-test contamination and follows the pattern established by
  # formatter_test.rb. The ensure block in the middleware normally clears this,
  # but we clean up explicitly to be safe.
  after do
    Thread.current[JsonRailsLogger::REQUEST_ID] = nil
    Object.send(:remove_const, 'Rails') if Object.const_defined?('Rails')
  end

  # Initialization and basic behavior tests
  it 'should initialise with an app' do
    _(middleware).must_be_kind_of(JsonRailsLogger::RequestIdMiddleware)
  end

  it 'should store the app instance' do
    _(middleware.instance_variable_get(:@app)).must_equal(app)
  end

  # Production environment tests: middleware should use HTTP_X_REQUEST_ID header
  describe 'Production environment' do
    it 'should extract request_id from HTTP_X_REQUEST_ID header in production' do
      setup_rails_env(development: false)

      # We use a capturing_app lambda to record the request_id value while the
      # middleware executes. This is necessary because the middleware's ensure block
      # clears Thread.current[JsonRailsLogger::REQUEST_ID] after execution completes.
      captured_request_id = nil
      capturing_app = lambda do |_env|
        captured_request_id = Thread.current[JsonRailsLogger::REQUEST_ID]
        [200, {}, ['OK']]
      end
      middleware_with_capturing_app = JsonRailsLogger::RequestIdMiddleware.new(capturing_app)

      env = { 'HTTP_X_REQUEST_ID' => 'prod-request-123' }
      middleware_with_capturing_app.call(env)

      _(captured_request_id).must_equal('prod-request-123')
    end

    it 'should handle missing HTTP_X_REQUEST_ID header in production' do
      setup_rails_env(development: false)
      env = { 'action_dispatch.request_id' => 'fallback-id' }
      middleware.call(env)
      # In production, the fallback is not used; request_id remains nil
      _(Thread.current[JsonRailsLogger::REQUEST_ID]).must_be_nil
    end

    it 'should return the result from the app' do
      setup_rails_env(development: false)
      env = { 'HTTP_X_REQUEST_ID' => 'prod-request-456' }
      response = middleware.call(env)
      # Middleware should pass through the app's response unchanged
      _(response).must_equal([200, {}, ['OK']])
    end

    it 'should clean up thread-local storage after request' do
      setup_rails_env(development: false)
      env = { 'HTTP_X_REQUEST_ID' => 'prod-request-789' }
      middleware.call(env)
      # The ensure block in middleware clears the thread-local value
      _(Thread.current[JsonRailsLogger::REQUEST_ID]).must_be_nil
    end

    it 'should clean up thread-local storage even if app raises exception' do
      setup_rails_env(development: false)
      env = { 'HTTP_X_REQUEST_ID' => 'prod-error-request' }
      failing_app = ->(_env) { raise StandardError, 'App error' }
      error_middleware = JsonRailsLogger::RequestIdMiddleware.new(failing_app)

      begin
        error_middleware.call(env)
      rescue StandardError
        # Expected: the app raises, but middleware's ensure block still runs
      end

      # Ensure block should have cleaned up even with exception
      _(Thread.current[JsonRailsLogger::REQUEST_ID]).must_be_nil
    end
  end

  # Development environment tests: middleware should use action_dispatch.request_id
  describe 'Development environment' do
    it 'should extract request_id from action_dispatch.request_id in development' do
      setup_rails_env(development: true)

      # See comment in production tests above about capturing_app.
      captured_request_id = nil
      capturing_app = lambda do |_env|
        captured_request_id = Thread.current[JsonRailsLogger::REQUEST_ID]
        [200, {}, ['OK']]
      end
      middleware_with_capturing_app = JsonRailsLogger::RequestIdMiddleware.new(capturing_app)

      env = { 'action_dispatch.request_id' => 'dev-request-123' }
      middleware_with_capturing_app.call(env)

      _(captured_request_id).must_equal('dev-request-123')
    end

    it 'should prefer action_dispatch.request_id over HTTP_X_REQUEST_ID in development' do
      setup_rails_env(development: true)

      captured_request_id = nil
      capturing_app = lambda do |_env|
        captured_request_id = Thread.current[JsonRailsLogger::REQUEST_ID]
        [200, {}, ['OK']]
      end
      middleware_with_capturing_app = JsonRailsLogger::RequestIdMiddleware.new(capturing_app)

      env = {
        'HTTP_X_REQUEST_ID' => 'http-header-id',
        'action_dispatch.request_id' => 'dispatch-id'
      }
      middleware_with_capturing_app.call(env)

      # In development, action_dispatch.request_id overrides HTTP_X_REQUEST_ID
      _(captured_request_id).must_equal('dispatch-id')
    end

    it 'should handle missing action_dispatch.request_id in development' do
      setup_rails_env(development: true)
      env = {}
      middleware.call(env)
      # If neither source provides a request_id, it remains nil
      _(Thread.current[JsonRailsLogger::REQUEST_ID]).must_be_nil
    end

    it 'should clean up thread-local storage in development' do
      setup_rails_env(development: true)
      env = { 'action_dispatch.request_id' => 'dev-request-456' }
      middleware.call(env)
      # The ensure block in middleware clears the thread-local value
      _(Thread.current[JsonRailsLogger::REQUEST_ID]).must_be_nil
    end
  end
end
