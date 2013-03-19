require 'feldtruby/float'

class TestFloat < MiniTest::Unit::TestCase
	def test_round_to_decimals
		assert_equal 1.2, 1.204.round_to_decimals(1)
		assert_equal 1.20, 1.204.round_to_decimals(2)
		assert_equal 1.204, 1.204.round_to_decimals(3)
	end
end

describe "protected_division_with" do
	it "works for non-zero values" do
		1.0.protected_division_with(2).must_equal 0.5
		120.4.protected_division_with(4).must_equal 30.1
	end

	it "returns positive infinity if numerator is positive and denominator is zero" do
		1.0.protected_division_with(0).must_equal 0.0
	end
end

describe 'to_significant_digits' do
	it 'can handle normal, floats around zero' do
		1.0.to_significant_digits(2).must_equal 1.0
		1.11.to_significant_digits(2).must_equal 1.1
		2.345.to_significant_digits(3).must_equal 2.35
		2.345.to_significant_digits(4).must_equal 2.345
		(-9.8654).to_significant_digits(3).must_equal -9.87
	end

	it 'can handle Infinity' do
		Float::INFINITY.to_significant_digits(2).must_equal Float::INFINITY
		(-Float::INFINITY).to_significant_digits(2).must_equal (-Float::INFINITY)
	end
end