require 'feldtruby/logger'

describe 'Logger' do

  before do
    @sio = StringIO.new
    @l = FeldtRuby::Logger.new @sio
  end

  it 'has a event count of 0 when no events has been logged' do

    @l.num_events.must_equal 0

  end

  it 'increases default event count when default events are logged' do

    @l.log "1"
    @l.num_events.must_equal 1

    @l.log "2"
    @l.num_events.must_equal 2

  end

  it 'can log default events (described in strings)' do

    @l.log "event 1"
    @sio.string.must_equal "event 1\n"
    @l.num_events.must_equal 1

    @l.log "event 2"
    @sio.string.must_equal "event 1\nevent 2\n"
    @l.num_events.must_equal 2

  end

  it 'can log events of a given type' do

    @l.log "1", :increase
    @sio.string.must_equal "{increase}: 1\n"
    @l.num_events.must_equal 0
    @l.num_events(:increase).must_equal 1

    @l.log "2", :increase
    @sio.string.must_equal "{increase}: 1\n{increase}: 2\n"
    @l.num_events.must_equal 0
    @l.num_events(:increase).must_equal 2

  end

  it 'can return old default events' do

    @l.log "event 1"
    @l.event_descriptions.must_equal ["event 1"]

    @l.log "event 2"
    @l.event_descriptions.must_equal ["event 1", "event 2"]

  end

  it 'can return old events of given type' do

    @l.log "1", :increase
    @l.log "2", :increase
    @l.log "0.4", :alpha
    @l.log "1", :increase

    @l.event_descriptions(:increase).must_equal ["{increase}: 1", "{increase}: 2", "{increase}: 1"]

    @l.event_descriptions(:alpha).must_equal ["{alpha}: 0.4"]

    @l.event_descriptions(:beta).must_equal []

  end

  it 'time stamps each log entry' do

    @l.log "1", :a
    @l.log "2", :b
    @l.log "2", :a

    time_stamps_a = @l.events(:a).map {|e| e.time_stamp}
    time_stamps_b = @l.events(:b).map {|e| e.time_stamp}

    time_stamps_a[0].must_be_instance_of Time
    time_stamps_a[1].must_be_instance_of Time
    time_stamps_b[0].must_be_instance_of Time

    time_stamps_a[0].must_be :<, time_stamps_a[1]
    time_stamps_a[0].must_be :<, time_stamps_b[0]
    time_stamps_b[0].must_be :<, time_stamps_a[1]

  end

  it 'can log to multiple io streams' do

    sio2 = StringIO.new
    @l.add_io sio2

    @l.log "a"

    @sio.string.must_equal "a\n"
    sio2.string.must_equal "a\n"

  end

end

describe 'StatisticsLogger - A Logger that adds specific functions to log the value of a metric' do
  before do
    @sio = StringIO.new
    @sl = FeldtRuby::StatisticsLogger.new @sio
  end

  it 'has a event count of 0 when no events has been logged' do

    @sl.num_events.must_equal 0

  end

end