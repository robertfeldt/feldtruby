require 'stringio'
require 'time'
require 'feldtruby/array/basic_stats'
require 'feldtruby/time'

module FeldtRuby

# A structured logging object that logs events. Events are time-stamped
# objects that have type and can contain arbitrary data. A logger can have
# multiple IO streams to which it logs events. With each event data can be
# saved.
#
# This default logger saves events locally in a hash. 
class Logger
  def initialize(io = STDOUT)

    @ios = []

    add_io io

    setup_data_store

    @start_time = Time.now

  end

  # Return the number of events of type _eventType_.
  def num_events eventType = nil
    events(eventType).length
  end

  # Return the elapsed time since the logger was started.
  def elapsed_time t = Time.now
    t - @start_time
  end

  # Add one more _io_ stream to which events are logged.
  def add_io io

    @ios << io
    @ios.uniq

  end

  # Events are time-stamped hashes of ruby values with a named type (given
  # as a string). The time stamps are always saved as UTC.
  class Event
    attr_reader :type, :data, :time
    def initialize(type, data, time = Time.now)
      @type, @data, @time = type, data, time
    end

    # Convert to json for saving in db. Since each event type is saved in its
    # own db/collection we do NOT include the event type.
    def to_db_json
      # We save with minimal json tag names since we need to conserve space
      # if saving this to disc or db.
      {
        # _id will be added automatically by MongoDB.
        "t" => time.utc.iso8601, # We follow the Cube convention of saving UTC
        "d" => data
      }.to_json(*a)
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

      # We only save the message if explicitly asked to and the :_m data
      # name not already used.
      data[:_m] = message if message && saveMessageInData && !data.has_key?(:_m)

      event = Event.new(eventType, data, time)

      save_event event

    end

    # Create a standard message for the change if no message given.
    unless message

      message = data.map do |metric, value|

        old_value = previous_value eventType, metric

        description_for_metric_change value, old_value, eventType, metric

      end.join("\n")

    end

    # We only print if enough time since last time we printed. This way
    # we avoid "flooding" the user with log messages.
    if elapsed >= printFrequency
      io_puts log_entry_description(message, eventType), time
    end

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

  UnixEpoch = Time.at(0)

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

  # Puts the given _message_ on the io stream(s) stamped with the given time.
  def io_puts message, time = Time.now

    s = time.strftime("%H:%M.%S%3N, ") + message

    @ios.each {|io| io.puts s}

  end

  # Save the event in the data store.
  def save_event event
    @events[event.type] << event
    event
  end

  # Prepend a tag describing the event type to _str_.
  def log_entry_description str, eventType = nil

    event_tag = eventType ? "{#{eventType.to_s}}: " : ""

    event_tag + str

  end

  def description_for_metric_change newValue, oldValue, eventType, metric

    pc = percent_change(oldValue, newValue)
    pcs = (pc ? " (#{pc})" : "")

    summary = summary_stats eventType, metric

    "#{format_number(oldValue)} -> #{format_number(newValue)}#{pcs}, mean = #{summary}"

  end

  def summary_stats eventType, metric
    values_for_event_and_metric(eventType, metric).summary_stats
  end

  def percent_change oldValue, newValue
    return nil if oldValue.nil?
    sign = (oldValue < newValue) ? "+" : ""
    "#{sign}%.1f%%" % ((newValue - oldValue) / oldValue.to_f * 100.0)
  end

  def format_number number, digits = 3
    if Float === number
      "%.#{digits}f" % number
    else
      number.to_s
    end
  end
end

# A simple logging interface front end for classes that need basic logging.
# Just include and call log or log_value. Uses a single common logger
# unless a new one has been explicitly set.
module Logging
  attr_accessor :logger

  def setup_logger_and_distribute_to_instance_variables(logger = nil)

    # Precedence for loggers if several has been setup:
    #  1. One specified as parameter to this method
    #  2. One that has already been set on this object
    #  3. First one found on an instance var
    #  4. Create a new standard one
    self.logger = logger || self.logger || find_logger_set_on_instance_vars() ||
      FeldtRuby::Logger.new

    # Now distribute the preferred logger to all instance vars, recursively.
    self.instance_variables.each do |ivar_name|

      ivar = self.instance_variable_get ivar_name

      if ivar.respond_to?(:setup_logger_and_distribute_to_instance_variables)
        ivar.setup_logger_and_distribute_to_instance_variables self.logger 
      end

    end

  end

  def find_logger_set_on_instance_vars

    # First see if we find it in the immediate ivars
    self.instance_variables.each do |ivar_name|

      ivar = self.instance_variable_get ivar_name

      if ivar.respond_to?(:logger)

        begin

          l = ivar.send(:logger)
          return l if l.is_a?(FeldtRuby::Logger)

        rescue Exception => e
        end

      end

    end

    # If we come here it means we did NOT find a logger in immediate
    # ivar's. So we recurse.
    self.instance_variables.each do |ivar_name|

      ivar = self.instance_variable_get ivar_name

      if ivar.respond_to?(:find_logger_set_on_instance_vars)

        begin

          l = ivar.send(:find_logger_set_on_instance_vars)
          return l if l.is_a?(FeldtRuby::Logger)

        rescue Exception => e
        end

      end

    end

    nil

  end

  def log message, eventType = nil, data = {}, saveMessageInData = true, printFrequency = 0.0
    logger.log message, eventType, data, saveMessageInData, printFrequency
  end

  def log_value eventType, newValue, message = nil, metric = :_v, printFrequency = 0.0
    logger.log_value eventType, newValue, message, metric, printFrequency
  end
end

end