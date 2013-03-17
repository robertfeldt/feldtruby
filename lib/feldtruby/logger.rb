require 'stringio'
require 'time'
require 'feldtruby/array/basic_stats'

module FeldtRuby

# A structured logging object that logs events. Events are time-stamped
# objects that have type and can contain arbitrary data. A logger can have
# multiple IO streams to which it logs events.
#
# This default logger saves events locally in a hash. 
class Logger
  def initialize(io = STDOUT)

    @ios = []

    add_io io

    # We save a unique array of events for each type.
    @events = Hash.new {|h,k| h[k] = Array.new}

  end

  # Add one more _io_ stream to which events are logged.
  def add_io io

    @ios << io
    @ios.uniq

  end

  # Puts the given _str_ on the io stream(s).
  def io_puts str
    @ios.each {|io| io.puts str}
  end

  # Return the number of events of type _eventType_.
  def num_events eventType = ""
    @events[eventType].length
  end

  # Events are time-stamped hashes of ruby values with a named type (given
  # as a string). The time stamps are always saved as UTC.
  class Event
    attr_reader :type, :data, :time_stamp
    def initialize(type, data, time = Time.now)
      @type, @data, @time_stamp = type, data, time.utc
    end

    # Convert to json for saving in db. Since each event type is saved in its
    # own db/collection we do NOT include the event type.
    def to_db_json
      # We save with minimal json tag names since we need to conserve space
      # if saving this to disc.
      {
        # _id will be added automatically by MongoDB if it is used.
        "t" => time.iso8601, # We follow the Cube convention of saving UTC
        "d" => data
      }.to_json(*a)
    end
  end

  # Save the event in the data store.
  def save_event event
    @events[event.type] << event
  end

  # Return all the events for a given _eventType_.
  def events(eventType = "")
    @events[eventType]
  end

  # Return all the event descriptions for a given _eventType_.
  def event_descriptions(eventType = "")
    @events[eventType].map {|e| e.data[:description]}
  end

  # Log an event described by a string _str_ optionally with an event type
  # _eventType_.
  def log str, eventType = ""

    description = log_entry_description(str, eventType)

    save_event Event.new(eventType, {:description => description})

    io_puts description

  end

  # Map a string and event type to a log string.
  def log_entry_description str, eventType = ""

    event_tag = eventType == "" ? "" : "{#{eventType.to_s}}: "

    event_tag + str

  end
end

class StatisticsLogger < Logger
  # Get an array of values for a metric.
  def values_for_metric metric

    event_name = event_name_for_metric metric

    events(event_name).map {|e| e.data[:v]}

  end

  # Return the current (latest) value for a given metric. Return nil if no
  # value has been set.
  def current_value(metric)
    values_for_metric(metric).last
  end

  # Log a new value for the metric named _metric_.
  def log_value newValue, metric = ""

    old_value = current_value metric

    save_event Event.new(event_name_for_metric(metric), {:v => newValue})

    io_puts description_for_metric_change(newValue, old_value, metric)

  end

  private

    def event_name_for_metric metric
    "metric_" + metric.to_s
  end

  def description_for_metric_change newValue, oldValue, metric

    pc = percent_change(oldValue, newValue)

    "#{metric.to_s} changed: #{format_number(oldValue)} -> #{format_number(newValue)} (#{pc}), mean = #{summary_stats(metric)}"

  end

  def summary_stats metric
    values_for_metric(metric).summary_stats
  end

  def percent_change oldValue, newValue
    return "N/A" if oldValue.nil?
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

end