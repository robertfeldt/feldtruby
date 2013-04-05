require 'feldtruby/version'
require 'feldtruby/logger'
require 'feldtruby/mongodb'

if FeldtRuby.is_mongo_running?

module FeldtRuby

# This is a class to access the main directory of all MongoDBLogger db's
# saved in a mongodb.
class AllMongoDBLoggers
  def initialize host, port
    @host, @port = host, port

    @client = Mongo::MongoClient.new("localhost", 27017)

    @main_db = @client.db("MongoDBLoggers")
  end

  def all_logs
    @main_db["all_logs"]
  end

  # Add a logger to the main dir of logger dbs.
  def add_logger(logger)

    db_logger_data = {
      "db_name" => logger.db_name,
      "logger_class" => logger.class.inspect,
      "gem" => "FeldtRuby",
      "gem_version" => FeldtRuby::VERSION,
      "start_time" => logger.start_time
    }

    all_logs.insert db_logger_data

  end

  def all_log_infos
    all_logs.find.to_a
  end

  def delete_logger_dbs skipLatestDb = true

    infos = all_log_infos.sort_by {|i| i["start_time"]}

    if skipLatestDb
      infos = infos - [infos.last]
    end

    infos.each {|i| drop_db_named(i["db_name"])}

  end

  # Drop the logger db with given name.
  def drop_db_named name

    @client.drop_database name

    all_logs.remove( {"db_name" => name} )

  end
end

# This is an EventLogger that logs to a MongoDB database. It caches
# the last two events per event type for quicker access to them.
class MongoDBLogger < Logger
  OurParams = {
    :host => "localhost",
    :port => 27017,
  }

  DefaultParams = FeldtRuby::Logger::DefaultParams.clone.update(OurParams)

  # I think this is needed since we have redefined DefaultParams but should
  # investigate...
  def initialize(io = STDOUT, params = DefaultParams)
    super
  end

  def unique_mongodb_name
    "MongoDBLogger_" + @start_time.utc.strftime("%Y%m%d_%H%M%S") + "_#{object_id}"
  end

  # Reader methods for the db and mongo client and db name.
  attr_reader :db, :mongo_client, :db_name

  # Set up the internal data store.
  def setup_data_store

    super

    # To handle the main "directory" of logger dbs in the mongodb.
    @all_dbs = FeldtRuby::AllMongoDBLoggers.new @params[:host], @params[:port]

    @mongo_client = Mongo::MongoClient.new @params[:host], @params[:port]

    @db_name = unique_mongodb_name()

    # Always creates a new db based on unique timestamp and object_id. The
    # latter is used to ensure each db has a unique name.
    @db = @mongo_client.db(@db_name)

    @all_dbs.add_logger self

    # Will map each event type to a collection in the db were we save
    # events for that type.
    @collections = Hash.new

    # Caches for the last and second_last events per type so we need
    # not lookup in db for most common requests.
    @cache_last = Hash.new
    @cache_2ndlast = Hash.new

  end

  # Reader methods for the main db and its all_logs collection. The latter is
  # the main "directory" for listing all available logs.
  attr_reader :main_db, :all_logs

  # Events are saved in the mongodb db, using one collection per event type.
  # The type itself is not saved in the event since it is implicit in the
  # collection in which the event is saved.
  def save_event event, type

    collection_for_type(type).insert event

    update_cache event, type

  end

  def update_cache event, type

    @cache_2ndlast[type] = @cache_last[type]

    @cache_last[type] = event

  end

  # Number of events of _eventType_ we have seen so far.
  def num_events eventType
    @counts[eventType]
  end

  # Log the event and print the message, if any.
  def log_event eventType, event, message = nil

    @counts[eventType] += 1

    if event

      event["t"] = Time.now.utc

      save_event(event, eventType)

      if message
        print_message_if_needed message, eventType, (eventType == "___default___")
      end

    end

    event

  end

  def collection_for_type(t)
    ts = t || "___default___"
    @collections[ts] ||= @db[ts.to_s]
  end

  def last_event eventType
    @cache_last[eventType]
  end

  def prev_event eventType
    @cache_2ndlast[eventType]
  end

  def last_value eventType
    current_value eventType
  end

  # Return the current (latest) value for a given eventType and metric. 
  # Return nil if no value has been set.
  def previous_value eventType, metric = "v"
    @cache_2ndlast[eventType][metric]
  end

  # Return the current (latest) value for a given eventType and metric. 
  # Return nil if no value has been set.
  def current_value eventType, metric = "v"
    @cache_last[eventType][metric]
  end

  # Return all the events for a given _eventType_.
  def events(eventType = nil)
    c = collection_for_type eventType
    c.find.to_a
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

  # Get an array of values for the metric named _metric_ in events
  # of type _eventType_.
  def values_for_event_and_metric eventType, metric = "v"
    events(eventType).map {|e| e.data[metric]}
  end

  # Shortcut method to get the value saved for a certain _eventType_.
  def values_for eventType
    values_for_event_and_metric eventType
  end
end

end

end