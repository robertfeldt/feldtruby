require 'feldtruby/time'

class TestFeldtRubyArray < MiniTest::Unit::TestCase
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
end
