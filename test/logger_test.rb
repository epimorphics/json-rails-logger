# frozen_string_literal: true

require 'minitest/autorun'
require './lib/json_rails_logger'

describe 'JsonRailsLogger::Logger' do
  it 'should support the silence method' do
    buf = StringIO.new
    fixture = JsonRailsLogger::Logger.new(buf)

    fixture.debug('test step 1')
    _(buf.string).must_match(/DEBUG.*test step 1/)

    buf.truncate(0)
    fixture.error('test step 2')
    _(buf.string).must_match(/ERROR.*test step 2/)

    buf.truncate(0)
    fixture.silence(Logger::ERROR) do
      fixture.error('test step 3')
    end
    _(buf.string).must_match(/ERROR.*test step 3/)

    buf.truncate(0)
    fixture.silence(Logger::ERROR) do
      fixture.debug('test step 4')
    end
    _(buf.string).must_equal('')
  end
end
