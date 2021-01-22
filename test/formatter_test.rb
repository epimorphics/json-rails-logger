# frozen_string_literal: true

require 'minitest/autorun'

require './lib/json_rails_logger.rb'

describe 'formatter' do
  describe 'json' do
    before do
      @json_formatter = JsonRailsLogger::JsonFormatter.new
      @json_formatter.datetime_format = '%Y-%m-%d %H:%M:%S'
      @time = DateTime.parse('2020-12-15T20:15:21')
      @progname = 'progname'
    end

    it 'should replace FATAL with ERROR for severity' do
      output = JSON.parse(@json_formatter.call('FATAL', @time, @progname,
                                               '[Webpacker] Compilation error!'))
      _(output['level']).must_equal('ERROR')
    end

    it 'should parse status messages to json' do
      output = JSON.parse(@json_formatter.call('INFO', @time, @progname, 'Status 200'))
      _(output['status']).must_equal('200')
    end

    it 'should parse method and path for requests' do
      output = JSON.parse(@json_formatter.call('INFO', @time, @progname, 'GET http://fsa-rp-test.epimorphics.net/'))
      _(output['method']).must_equal('GET')
      _(output['path']).must_equal('http://fsa-rp-test.epimorphics.net/')
    end

    it 'should parse user agent messages' do
      output = JSON.parse(@json_formatter.call('INFO', @time, @progname,
                                               "User-Agent: \"Faraday v1.3.0\"\nAccept: \"application/json\""))
      _(output['user_agent']).must_equal('Faraday v1.3.0')
      _(output['accept']).must_equal('application/json')
    end

    it 'should correctly format the timestamp' do
      output = JSON.parse(@json_formatter.call('INFO', @time, @progname,
                                               "[Webpacker] Everything's up-to-date. Nothing to do"))
      _(output['timestamp']).must_equal('2020-12-15 20:15:21')
    end

    it 'should move json to top level if message is json object' do
      json_object = {
        method: 'GET',
        path: 'http://fsa-rp-test.epimorphics.net/'
      }
      output = JSON.parse(@json_formatter.call('INFO', @time, @progname, json_object))
      _(output['method']).must_equal('GET')
      _(output['path']).must_equal('http://fsa-rp-test.epimorphics.net/')
    end
  end
end
