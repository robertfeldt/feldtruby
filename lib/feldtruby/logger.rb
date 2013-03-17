require 'stringio'

module FeldtRuby

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

  # Puts the given _str_ on the io stream.
  def io_puts str
    @ios.each {|io| io.puts str}
  end

  # Return the number of events of type _eventType_.
  def num_events eventType = nil
    @events[eventType].length
  end

  Event = Struct.new(:description, :time_stamp)

  # Count an event of type _eventType_.
  def log_event eventType = nil, description = ""
    @events[eventType] << Event.new(description, Time.now)
  end

  # Return all the events, i.e. descriptions and time stamp, for a given _eventType_.
  def events(eventType = nil)
    @events[eventType]
  end

  # Return all the event descriptions for a given _eventType_.
  def event_descriptions(eventType = nil)
    @events[eventType].map {|e| e.description}
  end

  # Log an event described by a string _str_ optionally with an event type
  # _eventType_.
  def log str, eventType = nil

    description = log_entry_description(str, eventType)

    log_event eventType, description

    io_puts description

  end

  # Map a string and event type to a log string.
  def log_entry_description str, eventType = nil

    event_tag = eventType ? "{#{eventType.to_s}}: " : ""

    event_tag + str

  end
end

class StatisticsLogger < Logger
  ValueChangeEvent = Struct.new(:value, :time_stamp)

  def log_value value, eventType = nil

  end
end

end