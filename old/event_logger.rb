class Logger
  private

  def description_for_metric_change newValue, oldValue, eventType, metric

    if newValue.is_a?(Numeric)

      pc = percent_change(oldValue, newValue)
      pcs = (pc ? " (#{pc})" : "")

      summary = summary_stats eventType, metric

      sum_str = summary ? ", mean = #{summary}" : ""

      ovstr = oldValue ? oldValue.to_significant_digits(3).to_s : ""

      "#{ovstr} -> #{newValue.to_significant_digits(3)}#{pcs}#{sum_str}"

    else

      "  was = #{oldValue.inspect}\n  now = #{newValue.inspect}"

    end
  end

  def summary_stats eventType, metric
    nil # We cannot calc summary stats since this logger does not save history
  end

  def percent_change oldValue, newValue
    return nil if oldValue.nil?
    sign = (oldValue < newValue) ? "+" : ""
    "#{sign}%.3g%%" % ((newValue - oldValue) / oldValue.to_f * 100.0)
  end
end

# A structured logging object that logs events. Events are time-stamped
# objects that have type and can contain arbitrary data. A logger can have
# multiple IO streams to which it logs events. With each event data can be
# saved.
#
# This default logger saves events locally in a hash. 
class EventLogger < Logger
  # Return the number of events of type _eventType_.
  def num_events eventType = nil
    events(eventType).length
  end

  # Events are time-stamped hashes of ruby values with a named type (given
  # as a string). The time stamps are always saved as UTC.
  class Event
    attr_reader :type, :data, :time
    def initialize(type, data, time = Time.now)
      @type, @data, @time = type, data, time
    end

    # Convert to hash that will be saved in db. Since each event type is saved in its
    # own db/collection we do NOT include the event type.
    def to_db_hash
      # We save with minimal json tag names since we need to conserve space
      # if saving this to disc or db.
      {
        # _id will be added automatically by MongoDB.
        "t" => time.utc.iso8601, # We follow the Cube convention of saving UTC
        "d" => data
      }
    end
  end

  # Return all the events for a given _eventType_.
  def events(eventType = nil)
    @events[eventType]
  end

  # Return all events, for a given _eventType_, between the _start_ and _stop_
  # times. If _includePreEvent_ is true we include the event that comes directly
  # before the start time.
  def events_between start, stop, eventType = nil, includePreEvent = false

    all_events = events(eventType)

    es = all_events.select do |e|

      t = e.time

      t >= start && t <= stop

    end

    if includePreEvent

      index_to_first_selected_event = all_events.index(es.first)

      if index_to_first_selected_event && index_to_first_selected_event > 0
        # There is a pre-event so add it
        es.unshift all_events[index_to_first_selected_event - 1]
      end

    end

    es

  end

  # Log an event described by a _message_ optionally with an event type
  # _eventType_ and data in a hash.
  #
  # The _printFrequency_ gives the minimum time that must elapse between
  # messages for _eventType_ is printed on the IO stream(s).
  def log message, eventType = nil, data = {}, saveMessageInData = true, printFrequency = 0.0

    # Get current time now, before we waste time in processing this event
    time, elapsed = time_and_elapsed_time_since_last_event eventType

    event = nil # So we return nil if no event was created

    # We only save the event if an eventType or data was given.
    if eventType || data.length > 0

      event = Event.new(eventType, data, time)

      save_event event

    end

    print_message_if_needed message, eventType, printFrequency, time

    event

  end

  # Log a _newValue_ for the _eventType_. Optionally a message and a name
  # for a metric can be given but if not we use sensible defaults.
  def log_value eventType, newValue, message = nil, metric = :_v, printFrequency = 0.0

    log message, eventType, {metric => newValue}, false, printFrequency

  end

  # Get an array of values for the metric named _metric_ in events
  # of type _eventType_.
  def values_for_event_and_metric eventType, metric = :_v
    events(eventType).map {|e| e.data[metric]}
  end

  # Return the current (latest) value for a given eventType and metric. 
  # Return nil if no value has been set.
  def current_value eventType, metric = :_v

    event = events(eventType).last

    return nil unless event

    event.data[metric]

  end

  # Shortcut method to get the value saved for a certain _eventType_.
  def values_for eventType
    values_for_event_and_metric eventType
  end

  # Return the current (latest) value for a given eventType and metric. 
  # Return nil if no value has been set.
  def previous_value eventType, metric = :_v

    event = events(eventType)[-2]

    return nil unless event

    event.data[metric]

  end

  # Return the values at each _step_ between _start_ (inclusive) and _stop_
  # (exclusive) for _eventType_ and _metric_. Both _start_, _stop_ can be 
  # either a Time object or a number of milli seconds (if they are integers). 
  # The _step_ should be given as milliseconds and defaults to one second, 
  # i.e. 1_000.
  def values_in_steps_between eventType, start = UnixEpoch, stop = Time.now, step = 1_000, metric = :_v

    # Get events in the given interval. Since we send true to this method
    # the events will include the one event prior to _start_ time if
    # it exists.
    events = events_between(start, stop, eventType, true)

    #puts events.inspect

    current_msec = start.is_a?(Integer) ? start : start.milli_seconds

    stop_msec = stop.is_a?(Integer) ? stop : stop.milli_seconds

    if events.first != nil && events.first.time.milli_seconds <= current_msec

      #puts "1"

      prev_value = events.first.data[metric]

      values_at_steps events.drop(1), current_msec, stop_msec, step, prev_value, metric

    else

      #puts "2"

      values_at_steps events, current_msec, stop_msec, step, nil, metric

    end

  end

  private

  def values_at_steps events, currentMsec, stopMsec, step, prevValue, metric

    #puts "curr = #{currentMsec}, stop = #{stopMsec}, step = #{step}, prevValue = #{prevValue}"

    e, *rest = events

    if e.nil?

      #puts "a"

      return [] if currentMsec >= stopMsec

      # No more events so fill up with prevValue
      [prevValue] * ((stopMsec - currentMsec) / step)

    else

      #puts "b"

      next_event_msec = e.time.milli_seconds

      q, m = (next_event_msec - currentMsec).divmod(step)

      vs = [prevValue] * q

      if m == 0
        if next_event_msec < stopMsec
          vs << e.data[metric]
        else
          return vs
        end
      else
        vs << prevValue
      end

      next_msec = currentMsec + (q + 1) * step

      vs + values_at_steps( rest, next_msec, stopMsec, step, e.data[metric], metric )

    end

  end

  # Set up the internal data store.
  def setup_data_store
    # For this default logger class we just use an array of the events for each
    # event type.
    @events = Hash.new {|h,k| h[k] = Array.new}
  end

  # Return the current time and elapsed time since we last logged an event of 
  # this type.
  # If a filter is given it is used to filter the events (of this type)
  # before selecting the one to compare current time to.
  def time_and_elapsed_time_since_last_event(eventType = nil, &filter)

    if filter
      latest = events(eventType).reverse.find(&filter)
    else
      latest = events(eventType).last
    end

    t = Time.now

    return [t, 0.0] unless latest

    return t, (t - latest.time)

  end

  # Save the event in the data store.
  def save_event event
    @events[event.type] << event
    event
  end

  def summary_stats eventType, metric
    values_for_event_and_metric(eventType, metric).summary_stats
  end
end

#describe 'EventLogger' do
#
#  before do
#    @sio = StringIO.new
#    @l = FeldtRuby::EventLogger.new @sio, {:verbose => true}
#  end
#
#
#  it 'returns an event from the log method if an event was logged' do
#
#    e = @l.log "1", :a
#    e.must_be_instance_of FeldtRuby::EventLogger::Event
#
#  end
#
#  it 'does not print messages to io stream(s) if verbose flag is false' do
#
#    sio = StringIO.new
#    l = FeldtRuby::EventLogger.new(sio, {:verbose => false})
#
#    l.log "event 1", :a
#    sio.string.must_equal ""
#
#    l.verbose = true
#    l.log "event 2", :a
#    sio.string.split("\n").last[13..-1].must_equal "{a}: event 2"
#
#    l.verbose = false
#    l.log "event 3", :a
#    sio.string.split("\n").last[13..-1].must_equal "{a}: event 2" # Still 2 since 3 was not printed
#
#  end
#
#  it 'can log events of a given type' do
#
#    @l.log "1", :increase
#    @sio.string[13..-1].must_equal "{increase}: 1\n"
#    @l.num_events.must_equal 0
#    @l.num_events(:increase).must_equal 1
#
#    @l.log "2", :increase
#    @sio.string[40..-1].must_equal "{increase}: 2\n"
#    @l.num_events.must_equal 0
#    @l.num_events(:increase).must_equal 2
#
#  end
#
#  it 'can return old events of given type' do
#
#    @l.log "1", :increase
#    @l.log "2", :increase
#    @l.log "0.4", :alpha
#    @l.log "1", :increase
#
#    ei = @l.events(:increase)
#    ei.length.must_equal 3
#
#    ea = @l.events(:alpha)
#    ea.length.must_equal 1
#
#    eb = @l.events(:beta)
#    eb.length.must_equal 0
#
#  end
#
#  it 'time stamps each log entry' do
#
#    @l.log "1", :a
#    @l.log "2", :b
#    @l.log "2", :a
#
#    time_stamps_a = @l.events(:a).map {|e| e.time}
#    time_stamps_b = @l.events(:b).map {|e| e.time}
#
#    time_stamps_a[0].must_be_instance_of Time
#    time_stamps_a[1].must_be_instance_of Time
#    time_stamps_b[0].must_be_instance_of Time
#
#    time_stamps_a[0].must_be :<, time_stamps_a[1]
#    time_stamps_a[0].must_be :<, time_stamps_b[0]
#    time_stamps_b[0].must_be :<, time_stamps_a[1]
#
#  end
#
#  it 'can log to multiple io streams' do
#
#    sio2 = StringIO.new
#    @l.add_io sio2
#
#    @l.log "a"
#
#    @sio.string[13..-1].must_equal "a\n"
#    sio2.string[13..-1].must_equal "a\n"
#
#  end
#
#  it 'has no value for a metric without events' do
#
#    @l.current_value(:fitness).must_equal nil
#
#  end
#
#  it 'can return the values logged so far' do
#
#    @l.log_value :a, 1.0
#    @l.previous_value(:a).must_equal nil
#    @l.current_value(:a).must_equal 1.0
#    @l.values_for_event_and_metric(:a, :_v).must_equal [1.0]
#    @l.values_for(:a).must_equal [1.0]
#
#    @l.log_value :a, 2.0
#    @l.previous_value(:a).must_equal 1.0
#    @l.current_value(:a).must_equal 2.0
#    @l.values_for_event_and_metric(:a, :_v).must_equal [1.0, 2.0]
#    @l.values_for(:a).must_equal [1.0, 2.0]
#
#    @l.log_value :a, 3.0
#    @l.previous_value(:a).must_equal 2.0
#    @l.current_value(:a).must_equal 3.0
#    @l.values_for_event_and_metric(:a, :_v).must_equal [1.0, 2.0, 3.0]
#    @l.values_for(:a).must_equal [1.0, 2.0, 3.0]
#
#  end
#
#  it 'updates the value when new values are logged' do
#
#    @l.current_value(:Fitness).must_equal nil
#
#    @l.log_value(:Fitness, 1.0)
#
#    expected1 = "{Fitness}:  -> 1.0, mean = 1 (min = 1, max = 1, median = 1, stdev = 0)\n"
#    @sio.string[13..-1].must_equal expected1
#
#    @l.current_value(:Fitness).must_equal 1.0
#
#    @l.log_value(:Fitness, 1.2)
#
#    @l.current_value(:Fitness).must_equal 1.2
#
#    expected2 = "{Fitness}: 1.0 -> 1.2 (+20%), mean = 1.1 (min = 1, max = 1.2, median = 1.1, stdev = 0.1)"
#    @sio.string.split("\n").last[13..-1].must_equal expected2
#
#    @l.log_value(:Fitness, 0.9)
#
#    @l.current_value(:Fitness).must_equal 0.9
#
#    expected3 = "{Fitness}: 1.2 -> 0.9 (-25%), mean = 1.03 (min = 0.9, max = 1.2, median = 1, stdev = 0.125)"
#    @sio.string.split("\n").last[13..-1].must_equal expected3
#
#    @l.current_value(:F).must_equal nil
#
#    @l.log_value(:F, 42.0)
#
#    expected4 = "{F}:  -> 42.0, mean = 42 (min = 42, max = 42, median = 42, stdev = 0)"
#    @sio.string.split("\n").last[13..-1].must_equal expected4
#
#  end
#
#  describe "an timed scenario of adding multiple events" do
#
#    before do
#      @t0 = Time.now
#      sleep 0.01
  #
#      @t1 = Time.now
#      sleep 0.01
#
#      @l.log "1", :a
#
#      e = @l.log_value :c, 10
#      @tc10 = e.time
#
#      @t2 = Time.now
#      sleep 0.01
#      e = @l.log "2", :a
#      @ta2 = e.time
#
#      @t3 = Time.now
#      sleep 0.01
#      @l.log "3", :a
  #
#      @t4 = Time.now
#      sleep 0.01
#      @l.log "1", :b
#      e = @l.log_value :c, 20
#      @tc20 = e.time
  #
#      @t5 = Time.now
#      sleep 0.01
#      @l.log "4", :a
  #
#      sleep 0.01
#      @t6 = Time.now
  #
#      sleep 0.01
#      @t7 = Time.now
#    end
#
#    it 'can return events between certain times' do
#
#      @l.events_between(@t0, @t1, :a).length.must_equal 0
  #
#      @l.events_between(@t1, @t6, :a).length.must_equal 4
#      @l.events_between(@t1, @t6, :a).map {|e| e.data[:_m]}.must_equal ["1", "2", "3", "4"]
  #
#      @l.events_between(@t2, @t6, :a).length.must_equal 3
#      @l.events_between(@t2, @t6, :a).map {|e| e.data[:_m]}.must_equal ["2", "3", "4"]
  #
#      @l.events_between(@t3, @t6, :a).length.must_equal 2
#      @l.events_between(@t3, @t6, :a).map {|e| e.data[:_m]}.must_equal ["3", "4"]
  #
#      @l.events_between(@t4, @t6, :a).length.must_equal 1
#      @l.events_between(@t4, @t6, :a).map {|e| e.data[:_m]}.must_equal ["4"]
  #
#      @l.events_between(@t5, @t6, :a).length.must_equal 1
#      @l.events_between(@t5, @t6, :a).map {|e| e.data[:_m]}.must_equal ["4"]
  #
#      @l.events_between(@t6, @t7, :a).length.must_equal 0
#      @l.events_between(@t6, @t7, :a).map {|e| e.data[:_m]}.must_equal []
  #
#      @l.events_between(@t6, @t7, :b).length.must_equal 0
#      @l.events_between(@t6, @t7, :b).map {|e| e.data[:_m]}.must_equal []
  #
#      @l.events_between(@t4, @t5, :b).length.must_equal 1
#      @l.events_between(@t4, @t5, :b).map {|e| e.data[:_m]}.must_equal ["1"]
  #
#      @l.events_between(@t1, @t7, :b).map {|e| e.data[:_m]}.must_equal ["1"]
#      @l.events_between(@t2, @t7, :b).map {|e| e.data[:_m]}.must_equal ["1"]
#      @l.events_between(@t3, @t7, :b).map {|e| e.data[:_m]}.must_equal ["1"]
  #
#      @l.events_between(@t1, @t6, :c).map {|e| e.data[:_v]}.must_equal [10, 20]
#      @l.events_between(@t1, @t2, :c).map {|e| e.data[:_v]}.must_equal [10]
#      @l.events_between(@t2, @t5, :c).map {|e| e.data[:_v]}.must_equal [20]
#      @l.events_between(@t6, @t7, :c).map {|e| e.data[:_v]}.must_equal []
#
#    end
#
#    it 'can return a pre-event to a time interval if asked to' do
#
#      @l.events_between(@tc10, @t3, :c).length.must_equal 1
#      @l.events_between(@tc10, @t3, :a).length.must_equal 1
#
#      @l.events_between(@tc10, @t3, :c, true).length.must_equal 1
#      @l.events_between(@tc10, @t3, :a, true).length.must_equal 2
#
#    end
#
#    # Sleep time above was 0.01 secs => 10 msecs. So what happened is:
#    #  @t0, 10ms, t1, 10ms, a="1", c=10, t2, 10ms, 
#    #  a="2", t3, 10ms, a="3", t4, 10ms, b="1", c=20, t5, 10ms, a="4",
#    #  10ms, t6, 10ms, t7
#
#    it "can return values in steps in intervals when there are no events" do
#
#      @l.values_in_steps_between(:c, @t0, @t1, 5).must_equal [nil, nil]
#      @l.values_in_steps_between(:c, @t0, @t1, 10).must_equal [nil]
  #
#      @l.values_in_steps_between(:c, @t6, @t7, 5).must_equal [nil, nil]
#      @l.values_in_steps_between(:c, @t6, @t7, 10).must_equal [nil]
#
#    end
#
#    it "can return values in steps in intervals where there are events" do
#
#      sio = StringIO.new
#      l = FeldtRuby::EventLogger.new sio
#
#      t0 = Time.now
#      sleep 0.01
#      t1 = Time.now
#      sleep 0.01
#      td1 = l.log_value(:d, 1).time
#      sleep 0.01 
#      td2 = l.log_value(:d, 2).time
#      sleep 0.001
#      t2 = Time.now # t2 should be at least one msec later than td2
#      sleep 0.011
#      td3 = l.log_value(:d, 3).time
#      sleep 0.01
#      t3 = Time.now
#
#      l.values_in_steps_between(:d, t0, t1, 5).must_equal [nil, nil]
#
#      diff = td2.milli_seconds - td1.milli_seconds
#
#      l.values_in_steps_between(:d, td1, td2, diff-1).must_equal [1, 1]
#
#      # The stop time is exclusive so should NOT be included
#      l.values_in_steps_between(:d, td1, td2, diff).must_equal [1]
#      l.values_in_steps_between(:d, td1, td2, diff+1).must_equal [1]
#
#      l.values_in_steps_between(:d, td1, t2, diff-1).must_equal [1, 1]
#      l.values_in_steps_between(:d, td1, t2, diff).must_equal [1, 2]
#      l.values_in_steps_between(:d, td1, t2, diff+1).must_equal [1]
#
#      vs = l.values_in_steps_between(:d, t0, t3, 1)
#
#      n = 0
#      d = td1.milli_seconds - t0.milli_seconds
#      vs[n, d].must_equal( [nil] * d )
#
#      n += d
#      d = td2.milli_seconds - td1.milli_seconds
#      vs[n, d].must_equal( [1] * d )
#
#      n += d
#      d = td3.milli_seconds - td2.milli_seconds
#      vs[n, d].must_equal( [2] * d )
#
#      n += d
#      d = t3.milli_seconds - td3.milli_seconds
#      vs[n, d].must_equal( [3] * d )
#
#    end
#
#  end
#end
#
#describe "Adding logging to an object and its instance vars" do
#  class A
#    include FeldtRuby::Logging
#
#    def initialize(b)
#      @b = b
#      setup_logger_and_distribute_to_instance_variables()
#    end
#
#    def calc
#      log "entering calc"
#      val = 1 + @b.calc
#      log_value :res, val
#      val
#    end
#  end
#
#  class B
#    include FeldtRuby::Logging
#
#    def initialize(l = nil)
#      setup_logger_and_distribute_to_instance_variables l
#    end
#
#    def calc
#      log "entering B#calc"
#      v = rand(100)
#      log_value :b_res, v
#      v
#    end
#  end
#
#  before do
#    @b = B.new
#    @a = A.new @b
#  end
#
#  it 'sets up the sam logger in both A objects and their instance vars' do
#
#    @a.logger.is_a?(FeldtRuby::Logger).must_equal true
#
#    @b.logger.must_equal @a.logger
#
#  end
#
#  it 'uses an explicit logger supplied to a instance var also in the using object' do
#
#    l = FeldtRuby::EventLogger.new
#    b = B.new l
#    a = A.new b
#
#    b.logger.must_equal a.logger
#    a.logger.must_equal l
#
#  end
#
#  it 'logs to the logger' do
#
#    l = @a.logger
#    l.verbose = false # So we don't print them while testing...
#
#    res = @a.calc()
#    l.current_value(:res).must_equal res
#    l.current_value(:b_res).must_equal res-1
#
#    res = @a.calc()
#    l.current_value(:res).must_equal res
#    l.current_value(:b_res).must_equal res-1
#
#  end
#end