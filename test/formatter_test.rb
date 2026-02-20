# frozen_string_literal: true

require './test/test_helper'

describe 'JsonRailsLogger::JsonFormatter' do
  let(:fixture) do
    formatter = JsonRailsLogger::JsonFormatter.new(include_optional: true)
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'
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

  it 'should correctly add the request id to returning json' do
    message = "Everything's up-to-date. Nothing to do"
    request_id_fixture = 'example-8a3fb0-request-30dgh0e-id'

    begin
      Thread.current[JsonRailsLogger::REQUEST_ID] = request_id_fixture

      log_output = fixture.call('INFO', timestamp, progname, message)
      _(log_output).must_be_kind_of(String)

      json_output = JSON.parse(log_output)
      _(json_output['request_id']).must_equal(request_id_fixture)
    ensure
      Thread.current[JsonRailsLogger::REQUEST_ID] = nil
    end
  end

  it 'should correctly format a microsecond duration into milliseconds' do
    message = '{"request_time": 1234567.89}'

    log_output = fixture.call('INFO', timestamp, progname, message)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    _(json_output['request_time']).must_equal(1_234_568)
  end

  it 'should exclude optional fields by default' do
    formatter = JsonRailsLogger::JsonFormatter.new
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    message = "User-Agent: \"Test-Agent\"\nAccept: \"application/json\""
    log_output = formatter.call('INFO', timestamp, progname, message)
    json_output = JSON.parse(log_output)

    _(json_output['user_agent']).must_be_nil
    _(json_output['accept']).must_be_nil
  end

  it 'should include optional message fields when configured' do
    formatter = JsonRailsLogger::JsonFormatter.new(include_optional: true)
    formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    message = "User-Agent: \"Test-Client\"\nAccept: \"application/json\""
    log_output = formatter.call('INFO', timestamp, progname, message)
    json_output = JSON.parse(log_output)

    _(json_output['user_agent']).wont_be_nil
    _(json_output['accept']).wont_be_nil
  end

  it 'should handle nil severity without truncation errors' do
    formatter = JsonRailsLogger::JsonFormatter.new(include_optional: true)
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

  it 'should maintain consistent required fields regardless of optional inclusion' do
    formatter_with_optional = JsonRailsLogger::JsonFormatter.new(include_optional: true)
    formatter_without_optional = JsonRailsLogger::JsonFormatter.new(include_optional: false)

    [formatter_with_optional, formatter_without_optional].each do |formatter|
      formatter.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'
      log_output = formatter.call('INFO', timestamp, progname, 'Status 200')
      json_output = JSON.parse(log_output)

      _(json_output['ts']).must_equal('2020-12-15T20:15:21.286Z')
      _(json_output['level']).must_equal('INFO')
      _(json_output['status']).must_equal(200)
    end
  end

  it 'should format completion message with controller and action' do
    formatter_with_optional = JsonRailsLogger::JsonFormatter.new(include_optional: true)
    formatter_without_optional = JsonRailsLogger::JsonFormatter.new(include_optional: false)
    formatter_with_optional.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'
    formatter_without_optional.datetime_format = '%Y-%m-%dT%H:%M:%S.%3NZ'

    # Use the existing user agent message format which naturally produces optional fields
    message = "User-Agent: \"Mozilla/5.0\"\nAccept: \"text/html\""

    log_with_optional = formatter_with_optional.call('INFO', timestamp, progname, message)
    log_without_optional = formatter_without_optional.call('INFO', timestamp, progname, message)

    json_with = JSON.parse(log_with_optional)
    json_without = JSON.parse(log_without_optional)

    # With include_optional=true, optional fields should be present
    _(json_with['user_agent']).must_equal('Mozilla/5.0')
    _(json_with['accept']).must_equal('text/html')

    # With include_optional=false, optional fields should be absent
    _(json_without['user_agent']).must_be_nil
    _(json_without['accept']).must_be_nil
  end
end
