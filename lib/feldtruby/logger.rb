require 'time'
require 'feldtruby/array/basic_stats'
require 'feldtruby/time'
require 'feldtruby/float'

module FeldtRuby

# Simplest possible logger only prints to STDOUT.
class Logger
  DefaultParams = {
    :verbose => true,
    :print_frequency => 0.3  # Minimum seconds between consecutive messages printed for the same event type
  }

  UnixEpoch = Time.at(0)

  attr_reader :start_time

  def initialize(io = STDOUT, params = DefaultParams)

    @start_time = Time.now

    @params = DefaultParams.clone.update(params)

    self.verbose = @params[:verbose]

    self.print_frequency = @params[:print_frequency]

    @ios = []

    add_io io

    setup_data_store

    @last_time_printed_for_event_type = Hash.new(UnixEpoch)

  end

  # Set up the internal data store.
  def setup_data_store
    # Nothing is saved by this simplest Logger, we just count them
    @counts = Hash.new(0)
  end

  # Number of events of _eventType_ we have seen so far.
  def num_events eventType = nil
    if eventType == nil
      @counts.values.sum
    else
      @counts[eventType]
    end
  end

  # Return the elapsed time since the logger was started.
  def elapsed_time t = Time.now
    t - @start_time
  end

  def verbose=(flag)
    @verbose = @params[:verbose] = flag
  end

  # Set the minimum time between printing successive messages of the same type.
  def print_frequency=(seconds = 1.0)
    @print_frequency = @params[:print_frequency] = seconds
  end

  # Add one more _io_ stream to which events are logged.
  def add_io io
    @ios << io
    @ios.uniq
  end

  def add_output_file(filename)
    @output_ios ||= []
    @output_ios << File.open(filename, "w")
    add_io @output_ios.last
    ObjectSpace.define_finalizer(self) do
      @output_ios.each {|fh| fh.close}
    end
  end

  # Events:
  #
  # An event is a hash with the keys:
  #  "t" => time of event in UTC
  #  "v" => optional value of the event, this is singled out for perf reasons, 
  #           it could also be saved in the data ("d")
  #  "d" => optional hash with additional data for the event
  #
  # An event which has a value but no data is called a value event.
  # A value event where the value is a number is called a number event.
  # An event with data is called a data event.
  # An event with only a message is called a message event. This is saved
  #   as a data event of type "___default___", with the message in e["d"]["m"].
  # An event can also be a counter event. Counter events are not logged, we just
  #   count how many they are.

  # Log a counter event, i.e. update the (local) count of how many times
  # this event has happened.
  def log_counter eventType, message = nil
    if message
      log_event eventType, nil, message
    else
      # We count it even if should not log it
      @counts[eventType] += 1
    end
  end

  # Log a value event.
  def log_value eventType, value, message = nil
    log_event eventType, {"v" => value}, message
  end

  # Log a data event.
  def log_data eventType, data, message = nil
    log_event eventType, {"d" => data}, message
  end

  # Log a message event.
  def log message
    log_event "___default___", {"d" => {"m" => message}}, message
  end

  # Log the event and print the message, if any. This simplest logger
  # only prints, it never saves the event.
  def log_event eventType, event, message = nil

    @counts[eventType] += 1

    if message
      print_message_if_needed message, eventType, (eventType == "___default___")
    end

    event

  end

  def print_message_if_needed message, eventType, skipCheck = false
    time = Time.now.utc

    # We only print if enough time since last time we printed. This way
    # we avoid "flooding" the user with log messages of the same type.
    if skipCheck || (time - @last_time_printed_for_event_type[eventType]) >= @print_frequency

      io_puts message, time

      @last_time_printed_for_event_type[eventType] = time

    end
  end

  # Puts the given _message_ on the io stream(s) stamped with the given time.
  def io_puts message, time = Time.now

    return unless @verbose

    elapsed_str = Time.human_readable_timestr elapsed_time(time)

    s = time.strftime("\n%H:%M.%S%3N (#{elapsed_str}), ") + message

    @ios.each {|io| io.puts s}

  end

end

# A simple logging interface front end for classes that need basic logging.
# Just include and call log methods on logger. Uses a single common logger
# unless a new one is been explicitly specified..
module Logging
  attr_accessor :logger

  def setup_logger_and_distribute_to_instance_variables(logger = nil)

    # Precedence for loggers if several has been setup:
    #  1. One specified as parameter to this method
    #  2. One that has already been set on this object
    #  3. First one found on an instance var
    #  4. Create a new standard one
    self.logger = logger || self.logger || __find_logger_set_on_instance_vars() ||
      new_default_logger()

    # Now distribute the preferred logger to all instance vars, recursively.
    self.instance_variables.each do |ivar_name|

      ivar = self.instance_variable_get ivar_name

      if ivar.respond_to?(:setup_logger_and_distribute_to_instance_variables)
        ivar.setup_logger_and_distribute_to_instance_variables self.logger 
      end

    end

  end

  # Override to use another logger as default if no logger is found.
  def new_default_logger
    FeldtRuby::Logger.new
  end

  # Find a logger if one has been set on any of my instance vars or their
  # instance vars (recursively).
  def __find_logger_set_on_instance_vars

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
end

end