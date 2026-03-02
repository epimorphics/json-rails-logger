# frozen_string_literal: true

require './test/test_helper'

describe 'JsonRailsLogger::JsonFormatter' do
  let(:fixture) do
  formatter = JsonRailsLogger::JsonFormatter.new
    formatter
  end

  let(:timestamp) { Time.parse('2020-12-15 20:15:21.286') }
  let(:progname) { 'progname' }

  it 'should replace FATAL with ERROR for severity' do
    message = '[Webpacker] Compilation error!'

    log_output = fixture.call('FATAL', timestamp, progname, message)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    _(json_output['level']).must_equal('ERROR')
  end

  it 'should parse status messages to json' do
    message = 'Status 200'

    log_output = fixture.call('INFO', timestamp, progname, message)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    _(json_output['status']).must_equal(200)
  end

  it 'should parse method and path for requests' do
    message = 'GET http://fsa-rp-test.epimorphics.net/'

    log_output = fixture.call('INFO', timestamp, progname, message)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    _(json_output['method']).must_equal('GET')
    _(json_output['path']).must_equal('http://fsa-rp-test.epimorphics.net/')
  end

  it 'should parse user agent messages' do
    message = "User-Agent: \"Faraday v1.3.0\"\nAccept: \"application/json\""

    log_output = fixture.call('INFO', timestamp, progname, message)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)

    _(json_output['user_agent']).must_equal('Faraday v1.3.0')
    _(json_output['accept']).must_equal('application/json')
  end

  it 'should correctly format the timestamp' do
    message = "Everything's up-to-date. Nothing to do"

    log_output = fixture.call('INFO', timestamp, progname, message)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    _(json_output['ts']).must_equal('2020-12-15T20:15:21.286Z')
  end

  it 'should move json to top level if message is json object' do
    json_fixture = {
      method: 'GET',
      path: 'http://fsa-rp-test.epimorphics.net/'
    }

    log_output = fixture.call('INFO', timestamp, progname, json_fixture)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    _(json_output['method']).must_equal('GET')
    _(json_output['path']).must_equal('http://fsa-rp-test.epimorphics.net/')
  end

  it 'should correctly format a microsecond duration into milliseconds' do
    message = '{"request_time": 1234567.89}'

    log_output = fixture.call('INFO', timestamp, progname, message)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    _(json_output['request_time']).must_equal(1_234_568)
  end

  it 'should include user_agent and accept from user-agent headers' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    message = "User-Agent: \"Test-Agent\"\nAccept: \"application/json\""
    log_output = formatter.call('INFO', timestamp, progname, message)
    json_output = JSON.parse(log_output)

    _(json_output['user_agent']).must_equal('Test-Agent')
    _(json_output['accept']).must_equal('application/json')
  end

  it 'should handle nil severity without truncation errors' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    log_output = formatter.call(nil, timestamp, progname, 'Status 200')
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    _(json_output).must_include('ts')
    _(json_output).must_include('status')
  end

  it 'should place ts and level first in JSON output' do
    message = 'Status 200'

    log_output = fixture.call('INFO', timestamp, progname, message)
    json_output = JSON.parse(log_output)

    keys = json_output.keys
    _(keys[0]).must_equal('ts')
    _(keys[1]).must_equal('level')
  end

  it 'should always include required fields in output' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    log_output = formatter.call('INFO', timestamp, progname, 'Status 200')
    json_output = JSON.parse(log_output)

    _(json_output['ts']).must_equal('2020-12-15T20:15:21.286Z')
    _(json_output['level']).must_equal('INFO')
    _(json_output['status']).must_equal(200)
  end

  it 'should format a complete request event' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    # Simulate a typical data query request
    request_event = {
      method: 'GET',
      path: '/api/datasets/ukhpi/query',
      format: 'json',
      controller: 'Api::DatasetsController',
      action: 'query',
      status: 200,
      duration: 145.67,
      view: 23.45,
      db: 98.34,
      params: { 'dataset' => 'ukhpi', 'limit' => '100' },
      user_agent: 'Mozilla/5.0'
    }

    log_output = formatter.call('INFO', timestamp, progname, request_event)
    json_output = JSON.parse(log_output)

    # Verify required fields are present
    _(json_output['ts']).must_equal('2020-12-15T20:15:21.286Z')
    _(json_output['level']).must_equal('INFO')
    _(json_output['method']).must_equal('GET')
    _(json_output['path']).must_equal('/api/datasets/ukhpi/query')
    _(json_output['status']).must_equal(200)
    _(json_output['request_time']).must_equal('0.146')

    # Verify ignored fields are excluded by default
    _(json_output['controller']).must_be_nil
    _(json_output['action']).must_be_nil
    _(json_output['user_agent']).must_be_nil

    # Verify params are excluded (not in REQUIRED_KEYS)
    _(json_output['params']).must_be_nil
  end

  it 'should handle request events with exceptions' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    # Simulate a data import validation failure
    request_event = {
      method: 'POST',
      path: '/api/imports/validate',
      controller: 'Api::ImportsController',
      action: 'validate',
      status: 422,
      duration: 234.56,
      exception: ['DataValidationError', 'Invalid CSV format: missing required column "region_code"'],
      exception_object: '#<DataValidationError: Invalid CSV format...>'
    }

    log_output = formatter.call('WARN', timestamp, progname, request_event)
    json_output = JSON.parse(log_output)

    # Verify exception info is included
    _(json_output['exception']).must_be_kind_of(Array)
    _(json_output['exception'][0]).must_equal('DataValidationError')
    _(json_output['exception'][1]).must_include('Invalid CSV format')

    # Verify status-based level normalization (422 → WARN)
    _(json_output['level']).must_equal('WARN')
    _(json_output['status']).must_equal(422)
  end

  it 'should compose message with controller and action details' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    # Simulate a dataset transformation request
    request_event = {
      method: 'PUT',
      path: '/api/datasets/ppd/transform',
      controller: 'Api::TransformationsController',
      action: 'apply',
      status: 200,
      duration: 567.89
    }

    log_output = formatter.call('INFO', timestamp, progname, request_event)
    json_output = JSON.parse(log_output)

    # Verify controller/action composition in message
    _(json_output['message']).must_match(/Transformations.*apply.*request complete/)
    _(json_output['controller']).must_equal('Api::TransformationsController')
    _(json_output['action']).must_equal('apply')
  end

  it 'should include request_id from thread storage with request event' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    request_id = 'data-export-abc123-def456'

    begin
      # Simulate middleware setting request ID
      Thread.current[JsonRailsLogger::REQUEST_ID] = request_id

      # Simulate a data export request
      request_event = {
        method: 'POST',
        path: '/api/exports/csv',
        controller: 'Api::ExportsController',
        action: 'create',
        status: 202,
        duration: 89.12
      }

      log_output = formatter.call('INFO', timestamp, progname, request_event)
      json_output = JSON.parse(log_output)

      # Verify request_id from thread storage is included
      _(json_output['request_id']).must_equal(request_id)
      _(json_output['method']).must_equal('POST')
      _(json_output['path']).must_equal('/api/exports/csv')
      _(json_output['status']).must_equal(202)
      _(json_output['request_time']).must_equal('0.089')
    ensure
      Thread.current[JsonRailsLogger::REQUEST_ID] = nil
    end
  end

  # Error handling tests
  it 'should handle malformed JSON gracefully' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    # Invalid JSON (missing closing brace)
    malformed_json = '{"method": "GET", "path": "/api/data"'

    log_output = formatter.call('INFO', timestamp, progname, malformed_json)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    # Should treat malformed JSON as a regular string and process it
    # Since it doesn't match status/request/user-agent patterns, it becomes a message
    _(json_output['ts']).must_equal('2020-12-15T20:15:21.286Z')
    _(json_output['level']).must_equal('INFO')
    # The formatter should not crash on malformed JSON
  end

  it 'should handle invalid severity values gracefully' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    # Invalid severity: empty string
    log_output = formatter.call('', timestamp, progname, 'Test message')
    _(log_output).must_be_kind_of(String)
    json_output = JSON.parse(log_output)
    # Empty severity gets processed as empty string (not nil)
    _(json_output['level']).must_equal('')

    # Unknown severity: completely unknown
    log_output = formatter.call('SUPERSEVERE', timestamp, progname, 'Another test')
    _(log_output).must_be_kind_of(String)
    json_output = JSON.parse(log_output)
    # Unknown severity is processed without crashing
    _(json_output).must_include('ts')
    _(json_output).must_include('level')
  end

  it 'should handle edge-case request_time values' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    # Extremely large duration (1 hour in milliseconds)
    large_request_event = {
      method: 'POST',
      path: '/api/imports/process-bulk',
      status: 200,
      duration: 3_600_000.0
    }

    log_output = formatter.call('INFO', timestamp, progname, large_request_event)
    json_output = JSON.parse(log_output)
    _(json_output['request_time']).must_equal(3_600_000)

    # Very small duration (1 microsecond)
    tiny_request_event = {
      method: 'GET',
      path: '/api/health',
      status: 200,
      duration: 0.001
    }

    log_output = formatter.call('INFO', timestamp, progname, tiny_request_event)
    json_output = JSON.parse(log_output)
    _(json_output['request_time']).must_equal(0)

    # Zero duration
    zero_request_event = {
      method: 'GET',
      path: '/api/cache-hit',
      status: 200,
      duration: 0
    }

    log_output = formatter.call('INFO', timestamp, progname, zero_request_event)
    json_output = JSON.parse(log_output)
    _(json_output['request_time']).must_be_nil

    # nil request_time (should not appear in output due to compact filter)
    nil_request_event = {
      method: 'DELETE',
      path: '/api/cleanup',
      status: 204,
      request_time: nil
    }

    log_output = formatter.call('INFO', timestamp, progname, nil_request_event)
    json_output = JSON.parse(log_output)
    _(json_output['request_time']).must_be_nil

    # false request_time (stays as false, not filtered as it's a falsy value)
    false_request_event = {
      method: 'PATCH',
      path: '/api/updates',
      status: 200,
      request_time: false
    }

    log_output = formatter.call('INFO', timestamp, progname, false_request_event)
    json_output = JSON.parse(log_output)
    # false is kept as-is by compact filter (only removes nil, not false)
    _(json_output['request_time']).must_equal(false)
  end

  it 'should handle circular references without crashing' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    # Create an object with circular reference
    circular_data = {
      method: 'GET',
      path: '/api/data',
      status: 200
    }
    # Create the circular reference
    circular_data[:self_reference] = circular_data

    # The formatter should either handle this gracefully or raise a clear error
    begin
      log_output = formatter.call('INFO', timestamp, progname, circular_data)
      _(log_output).must_be_kind_of(String)
      # If it succeeds, verify basic structure is intact
      json_output = JSON.parse(log_output)
      _(json_output['ts']).must_equal('2020-12-15T20:15:21.286Z')
    rescue JSON::GeneratorError => e
      # If it raises GeneratorError (expected for circular refs), that's acceptable
      _(e.message).must_include('circular')
    end
  end
end
