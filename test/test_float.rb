require 'feldtruby/float'

class TestFloat < MiniTest::Unit::TestCase
	def test_round_to_decimals
		assert_equal 1.2, 1.204.round_to_decimals(1)
		assert_equal 1.20, 1.204.round_to_decimals(2)
		assert_equal 1.204, 1.204.round_to_decimals(3)
	end
end