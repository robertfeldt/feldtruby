require 'feldtruby/logger'
require 'stringio'

describe 'Logger' do

  before do
    @sio = StringIO.new
    @l = FeldtRuby::Logger.new @sio, {:verbose => true, 
      :print_frequency => 0.0 # So everything is logged
    }
  end

  it 'has a event count of 0 when no events has been logged' do
    @l.num_events.must_equal 0
  end

  it 'can log counter events' do

    @l.num_events(:a).must_equal 0

    @l.log_counter :a
    @l.num_events(:a).must_equal 1

    @l.log_counter :a
    @l.num_events(:a).must_equal 2

  end

  it 'can log default events (described in strings)' do

    @l.log "event 1"
    @sio.string.split("\n").last[-7..-1].must_equal "event 1"
    @l.num_events.must_equal 1

    @l.log "event 2"
    @sio.string.split("\n").last[-7..-1].must_equal "event 2"
    @l.num_events.must_equal 2

  end

end

describe 'Logger with a non-zero print frequency' do

  before do
    @sio = StringIO.new
    @l = FeldtRuby::Logger.new @sio, {:verbose => true, 
      :print_frequency => 0.1
    }
  end

  it 'only logs if log event comes less often than the print frequency' do

    @l.log "event 1"
    @l.num_events.must_equal 1

    # This event comes right after so is only counted, not printed
    @l.log "event 2"
    @l.num_events.must_equal 2
    @sio.string.split("\n").last[-7..-1].must_equal "event 1"

    # Ensure we have waited longer than print frequency
    sleep 0.1
    @l.log "event 3"
    @l.num_events.must_equal 3
    @sio.string.split("\n").last[-7..-1].must_equal "event 3"

  end

end

describe 'Logger with two IO output streams' do
  it 'logs to all streams of more than one' do
    sio1 = StringIO.new
    l = FeldtRuby::Logger.new sio1, {:verbose => true, 
      :print_frequency => 0.0
    }
    sio2 = StringIO.new
    l.add_io sio2

    l.log "event 1"
    l.num_events.must_equal 1
    sio1.string.split("\n").last[-7..-1].must_equal "event 1"
    sio2.string.split("\n").last[-7..-1].must_equal "event 1"

    sio3 = StringIO.new
    l.add_io sio3
    l.log "event 2"
    l.num_events.must_equal 2
    sio1.string.split("\n").last[-7..-1].must_equal "event 2"
    sio2.string.split("\n").last[-7..-1].must_equal "event 2"
    sio3.string.split("\n").last[-7..-1].must_equal "event 2"
  end

  it 'can add filenames to which log output should be written' do
    sio1 = StringIO.new
    l = FeldtRuby::Logger.new sio1, {:verbose => true, 
      :print_frequency => 0.0
    }

    filename = "temp390580943850834.log"

    File.delete filename if File.exist?(filename)
    l.add_output_file filename

    l.log "event 1"
    File.exist?(filename).must_equal true
    File.delete filename

  end
end