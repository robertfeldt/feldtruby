require 'feldtruby/mongodb_logger'

if FeldtRuby.is_mongo_running?

describe 'AllMongoDBLoggers' do
  before do
    @adbs = FeldtRuby::AllMongoDBLoggers.new "localhost", 27017
    @l = FeldtRuby::MongoDBLogger.new
  end

  after do
    @adbs.drop_db_named @l.db_name
  end

  it 'can list all logs in the db, and there is at least one with the right name since we created one' do

    alis = @adbs.all_log_infos
    alis.must_be_instance_of Array

    dbn = alis.first["db_name"]
    dbn.must_match /MongoDBLogger_\d{8}_\d{6}_\d+/

  end

end

describe 'MongoDBLogger' do

  before do
    @sio = StringIO.new
    @l = FeldtRuby::MongoDBLogger.new @sio, {:verbose => true}
    @adbs = FeldtRuby::AllMongoDBLoggers.new "localhost", 27017
  end

  after do
    @adbs.drop_db_named @l.db_name
  end

  it 'can log counter events' do
    @l.num_events(:a).must_equal 0
    @l.log_counter :a
    @l.num_events(:a).must_equal 1
    @l.log_counter :a
    @l.num_events(:a).must_equal 2
  end

  it 'can log value events where the values are numbers' do

    @l.log_value :a, 2
    c = @l.collection_for_type :a
    c.find.to_a.length.must_equal 1

    @l.log_value :a, 3
    c.find.to_a.length.must_equal 2

    @l.current_value(:a).must_equal 3
    @l.previous_value(:a).must_equal 2

    @l.log_value :a, 4
    c.find.to_a.length.must_equal 3

    @l.log_value :b, -100
    cb = @l.collection_for_type :b
    cb.find.to_a.length.must_equal 1

    @l.current_value(:a).must_equal 4
    @l.previous_value(:a).must_equal 3

    @l.current_value(:b).must_equal -100

    es = @l.events(:a)

    es.length.must_equal 3

    es[0].keys.sort.must_equal ["_id", "t", "v"].sort
    es[1].keys.sort.must_equal ["_id", "t", "v"].sort
    es[2].keys.sort.must_equal ["_id", "t", "v"].sort

    es[0]["t"].micro_seconds.must_be :<=, es[1]["t"].micro_seconds
    es[1]["t"].micro_seconds.must_be :<=, es[2]["t"].micro_seconds

    es[0]["v"].must_equal 2
    es[1]["v"].must_equal 3
    es[2]["v"].must_equal 4

    @l.num_events(:a).must_equal 3

  end

  it 'can log data events' do

    @l.log_data :bg, {:a => 1, :b => 2}
    c = @l.collection_for_type :bg

    c.find.to_a.length.must_equal 1

    @l.log_data :bg, {:a => 3, :b => 4}

    es = c.find.to_a

    es.length.must_equal 2

    es[0]["d"]["a"].must_equal 1
    es[0]["d"]["b"].must_equal 2

    es[1]["d"]["a"].must_equal 3
    es[1]["d"]["b"].must_equal 4

  end
end

else

  puts "!!!!! NOTE !!!!!\n  Not testing MongoDBLogger since mongod is not running. Start with:\n    mongod\n!!!!!"

end