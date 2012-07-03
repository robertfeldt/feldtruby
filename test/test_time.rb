require 'feldtruby/time'

class TestFeldtRubyTime < MiniTest::Unit::TestCase
	def test_timestamp_short
		str = Time.timestamp({:short => true})
		assert_equal 15, str.length
		assert str =~ /^\d{6} \d{2}:\d{2}\.\d{2}/
	end

	def test_timestamp_long
		str = Time.timestamp()
		assert_equal 17, str.length
		assert str =~ /^\d{8} \d{2}:\d{2}\.\d{2}/
	end

	def test_human_readable_timestr
		assert_equal "74.92usec", Time.human_readable_timestr(0.000074916)
		assert_equal "0.75msec", Time.human_readable_timestr(0.00074916)
		assert_equal "7.49msec", Time.human_readable_timestr(0.0074916)
		assert_equal "74.92msec", Time.human_readable_timestr(0.074916)
		assert_equal "0.75sec", Time.human_readable_timestr(0.74916)
		assert_equal "7.49sec", Time.human_readable_timestr(7.4916)
		assert_equal "1.25mins", Time.human_readable_timestr(74.916)
		assert_equal "12.49mins", Time.human_readable_timestr(749.16)
		assert_equal "2.08hours", Time.human_readable_timestr(7491.6)
	end
end
