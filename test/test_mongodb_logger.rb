require 'feldtruby/mongodb_logger'

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

  end

end