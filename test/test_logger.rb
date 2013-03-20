require 'feldtruby/logger'

describe 'EventLogger' do

  before do
    @sio = StringIO.new
    @l = FeldtRuby::Logger.new @sio, {:verbose => true}
  end

  it 'can log default events' do

    @l.log "event 1"
    @sio.string.split("\n")[0][13..-1].must_equal "event 1"

    @l.log "event 2"
    @sio.string.split("\n")[1][13..-1].must_equal "event 2"

  end

  it 'can return the values logged so far' do

    @l.log_value :a, 1.0
    @sio.string.split("\n")[0][13..-1].must_equal "{a}: Value changed to 1.0"

  end
end

describe 'EventLogger' do

  before do
    @sio = StringIO.new
    @l = FeldtRuby::EventLogger.new @sio, {:verbose => true}
  end

  it 'has a event count of 0 when no events has been logged' do

    @l.num_events.must_equal 0

  end

  it 'does not return an event if nothing was logged' do

    e = @l.log "1"
    e.must_equal nil

  end

  it 'returns an event from the log method if an event was logged' do

    e = @l.log "1", :a
    e.must_be_instance_of FeldtRuby::EventLogger::Event

  end

  it 'does not log events without a type and data' do

    @l.log "1"
    @l.num_events.must_equal 0

    @l.log "2"
    @l.num_events.must_equal 0

    @l.log "3", nil, {:d => 1}
    @l.num_events.must_equal 1

    @l.log "1", "a"
    @l.num_events.must_equal 1
    @l.num_events("a").must_equal 1

    @l.log "2", "a"
    @l.num_events("a").must_equal 2

  end

  it 'can log default events (described in strings)' do

    @l.log "event 1", nil, {:d => 1}
    @sio.string.split("\n")[0][13..-1].must_equal "event 1"
    @l.num_events.must_equal 1

    @l.log "event 2", nil, {:d => 1}
    @sio.string.split("\n")[1][13..-1].must_equal "event 2"
    @l.num_events.must_equal 2

  end

  it 'does not print messages to io stream(s) if verbose flag is false' do

    sio = StringIO.new
    l = FeldtRuby::EventLogger.new(sio, {:verbose => false})

    l.log "event 1", :a
    sio.string.must_equal ""

    l.verbose = true
    l.log "event 2", :a
    sio.string.split("\n").last[13..-1].must_equal "{a}: event 2"

    l.verbose = false
    l.log "event 3", :a
    sio.string.split("\n").last[13..-1].must_equal "{a}: event 2" # Still 2 since 3 was not printed

  end

  it 'can log events of a given type' do

    @l.log "1", :increase
    @sio.string[13..-1].must_equal "{increase}: 1\n"
    @l.num_events.must_equal 0
    @l.num_events(:increase).must_equal 1

    @l.log "2", :increase
    @sio.string[40..-1].must_equal "{increase}: 2\n"
    @l.num_events.must_equal 0
    @l.num_events(:increase).must_equal 2

  end

  it 'can return old events of given type' do

    @l.log "1", :increase
    @l.log "2", :increase
    @l.log "0.4", :alpha
    @l.log "1", :increase

    ei = @l.events(:increase)
    ei.length.must_equal 3

    ea = @l.events(:alpha)
    ea.length.must_equal 1

    eb = @l.events(:beta)
    eb.length.must_equal 0

  end

  it 'time stamps each log entry' do

    @l.log "1", :a
    @l.log "2", :b
    @l.log "2", :a

    time_stamps_a = @l.events(:a).map {|e| e.time}
    time_stamps_b = @l.events(:b).map {|e| e.time}

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

    @sio.string[13..-1].must_equal "a\n"
    sio2.string[13..-1].must_equal "a\n"

  end

  it 'has no value for a metric without events' do

    @l.current_value(:fitness).must_equal nil

  end

  it 'can return the values logged so far' do

    @l.log_value :a, 1.0
    @l.previous_value(:a).must_equal nil
    @l.current_value(:a).must_equal 1.0
    @l.values_for_event_and_metric(:a, :_v).must_equal [1.0]
    @l.values_for(:a).must_equal [1.0]

    @l.log_value :a, 2.0
    @l.previous_value(:a).must_equal 1.0
    @l.current_value(:a).must_equal 2.0
    @l.values_for_event_and_metric(:a, :_v).must_equal [1.0, 2.0]
    @l.values_for(:a).must_equal [1.0, 2.0]

    @l.log_value :a, 3.0
    @l.previous_value(:a).must_equal 2.0
    @l.current_value(:a).must_equal 3.0
    @l.values_for_event_and_metric(:a, :_v).must_equal [1.0, 2.0, 3.0]
    @l.values_for(:a).must_equal [1.0, 2.0, 3.0]

  end

  it 'updates the value when new values are logged' do

    @l.current_value(:Fitness).must_equal nil

    @l.log_value(:Fitness, 1.0)

    expected1 = "{Fitness}:  -> 1.0, mean = 1 (min = 1, max = 1, median = 1, stdev = 0)\n"
    @sio.string[13..-1].must_equal expected1

    @l.current_value(:Fitness).must_equal 1.0

    @l.log_value(:Fitness, 1.2)

    @l.current_value(:Fitness).must_equal 1.2

    expected2 = "{Fitness}: 1.0 -> 1.2 (+20%), mean = 1.1 (min = 1, max = 1.2, median = 1.1, stdev = 0.1)"
    @sio.string.split("\n").last[13..-1].must_equal expected2

    @l.log_value(:Fitness, 0.9)

    @l.current_value(:Fitness).must_equal 0.9

    expected3 = "{Fitness}: 1.2 -> 0.9 (-25%), mean = 1.03 (min = 0.9, max = 1.2, median = 1, stdev = 0.125)"
    @sio.string.split("\n").last[13..-1].must_equal expected3

    @l.current_value(:F).must_equal nil

    @l.log_value(:F, 42.0)

    expected4 = "{F}:  -> 42.0, mean = 42 (min = 42, max = 42, median = 42, stdev = 0)"
    @sio.string.split("\n").last[13..-1].must_equal expected4

  end

  describe "an timed scenario of adding multiple events" do

    before do
      @t0 = Time.now
      sleep 0.01
  
      @t1 = Time.now
      sleep 0.01

      @l.log "1", :a

      e = @l.log_value :c, 10
      @tc10 = e.time

      @t2 = Time.now
      sleep 0.01
      e = @l.log "2", :a
      @ta2 = e.time

      @t3 = Time.now
      sleep 0.01
      @l.log "3", :a
  
      @t4 = Time.now
      sleep 0.01
      @l.log "1", :b
      e = @l.log_value :c, 20
      @tc20 = e.time
  
      @t5 = Time.now
      sleep 0.01
      @l.log "4", :a
  
      sleep 0.01
      @t6 = Time.now
  
      sleep 0.01
      @t7 = Time.now
    end

    it 'can return events between certain times' do

      @l.events_between(@t0, @t1, :a).length.must_equal 0
  
      @l.events_between(@t1, @t6, :a).length.must_equal 4
      @l.events_between(@t1, @t6, :a).map {|e| e.data[:_m]}.must_equal ["1", "2", "3", "4"]
  
      @l.events_between(@t2, @t6, :a).length.must_equal 3
      @l.events_between(@t2, @t6, :a).map {|e| e.data[:_m]}.must_equal ["2", "3", "4"]
  
      @l.events_between(@t3, @t6, :a).length.must_equal 2
      @l.events_between(@t3, @t6, :a).map {|e| e.data[:_m]}.must_equal ["3", "4"]
  
      @l.events_between(@t4, @t6, :a).length.must_equal 1
      @l.events_between(@t4, @t6, :a).map {|e| e.data[:_m]}.must_equal ["4"]
  
      @l.events_between(@t5, @t6, :a).length.must_equal 1
      @l.events_between(@t5, @t6, :a).map {|e| e.data[:_m]}.must_equal ["4"]
  
      @l.events_between(@t6, @t7, :a).length.must_equal 0
      @l.events_between(@t6, @t7, :a).map {|e| e.data[:_m]}.must_equal []
  
      @l.events_between(@t6, @t7, :b).length.must_equal 0
      @l.events_between(@t6, @t7, :b).map {|e| e.data[:_m]}.must_equal []
  
      @l.events_between(@t4, @t5, :b).length.must_equal 1
      @l.events_between(@t4, @t5, :b).map {|e| e.data[:_m]}.must_equal ["1"]
  
      @l.events_between(@t1, @t7, :b).map {|e| e.data[:_m]}.must_equal ["1"]
      @l.events_between(@t2, @t7, :b).map {|e| e.data[:_m]}.must_equal ["1"]
      @l.events_between(@t3, @t7, :b).map {|e| e.data[:_m]}.must_equal ["1"]
  
      @l.events_between(@t1, @t6, :c).map {|e| e.data[:_v]}.must_equal [10, 20]
      @l.events_between(@t1, @t2, :c).map {|e| e.data[:_v]}.must_equal [10]
      @l.events_between(@t2, @t5, :c).map {|e| e.data[:_v]}.must_equal [20]
      @l.events_between(@t6, @t7, :c).map {|e| e.data[:_v]}.must_equal []

    end

    it 'can return a pre-event to a time interval if asked to' do

      @l.events_between(@tc10, @t3, :c).length.must_equal 1
      @l.events_between(@tc10, @t3, :a).length.must_equal 1

      @l.events_between(@tc10, @t3, :c, true).length.must_equal 1
      @l.events_between(@tc10, @t3, :a, true).length.must_equal 2

    end

    # Sleep time above was 0.01 secs => 10 msecs. So what happened is:
    #  @t0, 10ms, t1, 10ms, a="1", c=10, t2, 10ms, 
    #  a="2", t3, 10ms, a="3", t4, 10ms, b="1", c=20, t5, 10ms, a="4",
    #  10ms, t6, 10ms, t7

    it "can return values in steps in intervals when there are no events" do

      @l.values_in_steps_between(:c, @t0, @t1, 5).must_equal [nil, nil]
      @l.values_in_steps_between(:c, @t0, @t1, 10).must_equal [nil]
  
      @l.values_in_steps_between(:c, @t6, @t7, 5).must_equal [nil, nil]
      @l.values_in_steps_between(:c, @t6, @t7, 10).must_equal [nil]

    end

    it "can return values in steps in intervals where there are events" do

      sio = StringIO.new
      l = FeldtRuby::EventLogger.new sio

      t0 = Time.now
      sleep 0.01
      t1 = Time.now
      sleep 0.01
      td1 = l.log_value(:d, 1).time
      sleep 0.01 
      td2 = l.log_value(:d, 2).time
      sleep 0.001
      t2 = Time.now # t2 should be at least one msec later than td2
      sleep 0.011
      td3 = l.log_value(:d, 3).time
      sleep 0.01
      t3 = Time.now

      l.values_in_steps_between(:d, t0, t1, 5).must_equal [nil, nil]

      diff = td2.milli_seconds - td1.milli_seconds

      l.values_in_steps_between(:d, td1, td2, diff-1).must_equal [1, 1]

      # The stop time is exclusive so should NOT be included
      l.values_in_steps_between(:d, td1, td2, diff).must_equal [1]
      l.values_in_steps_between(:d, td1, td2, diff+1).must_equal [1]

      l.values_in_steps_between(:d, td1, t2, diff-1).must_equal [1, 1]
      l.values_in_steps_between(:d, td1, t2, diff).must_equal [1, 2]
      l.values_in_steps_between(:d, td1, t2, diff+1).must_equal [1]

      vs = l.values_in_steps_between(:d, t0, t3, 1)

      n = 0
      d = td1.milli_seconds - t0.milli_seconds
      vs[n, d].must_equal( [nil] * d )

      n += d
      d = td2.milli_seconds - td1.milli_seconds
      vs[n, d].must_equal( [1] * d )

      n += d
      d = td3.milli_seconds - td2.milli_seconds
      vs[n, d].must_equal( [2] * d )

      n += d
      d = t3.milli_seconds - td3.milli_seconds
      vs[n, d].must_equal( [3] * d )

    end

  end
end

describe "Adding logging to an object and its instance vars" do
  class A
    include FeldtRuby::Logging

    def initialize(b)
      @b = b
      setup_logger_and_distribute_to_instance_variables()
    end

    def calc
      log "entering calc"
      val = 1 + @b.calc
      log_value :res, val
      val
    end
  end

  class B
    include FeldtRuby::Logging

    def initialize(l = nil)
      setup_logger_and_distribute_to_instance_variables l
    end

    def calc
      log "entering B#calc"
      v = rand(100)
      log_value :b_res, v
      v
    end
  end

  before do
    @b = B.new
    @a = A.new @b
  end

  it 'sets up the sam logger in both A objects and their instance vars' do

    @a.logger.is_a?(FeldtRuby::Logger).must_equal true

    @b.logger.must_equal @a.logger

  end

  it 'uses an explicit logger supplied to a instance var also in the using object' do

    l = FeldtRuby::EventLogger.new
    b = B.new l
    a = A.new b

    b.logger.must_equal a.logger
    a.logger.must_equal l

  end

  it 'logs to the logger' do

    l = @a.logger
    l.verbose = false # So we don't print them while testing...

    res = @a.calc()
    l.current_value(:res).must_equal res
    l.current_value(:b_res).must_equal res-1

    res = @a.calc()
    l.current_value(:res).must_equal res
    l.current_value(:b_res).must_equal res-1

  end
end