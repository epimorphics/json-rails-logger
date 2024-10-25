# frozen_string_literal: true

require './test/test_helper'

describe 'JsonRailsLogger::JsonFormatter' do
  let(:fixture) do
    formatter = JsonRailsLogger::JsonFormatter.new
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
    _(json_output['status']).must_equal('200')
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
    message = "[Webpacker] Everything's up-to-date. Nothing to do"

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
    message = "[Webpacker] Everything's up-to-date. Nothing to do"
    request_id_fixture = { 'request_id' => 'example-8a3fb0-request-30dgh0e-id' }

    fixture.stub :request_id, request_id_fixture do
      log_output = fixture.call('INFO', timestamp, progname, message)
      _(log_output).must_be_kind_of(String)

      json_output = JSON.parse(log_output)
      _(json_output['request_id']).must_equal(request_id_fixture['request_id'])
    end
  end

  it 'should correctly format a microsecond duration into milliseconds' do
    message = '{"duration": 1234567.89}'

    log_output = fixture.call('INFO', timestamp, progname, message)
    _(log_output).must_be_kind_of(String)

    json_output = JSON.parse(log_output)
    _(json_output['duration']).must_equal(1_234_568)
  end
end
