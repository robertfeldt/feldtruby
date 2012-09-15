require 'helper'
require 'feldtruby/array/basic_stats'

class TestArrayBasicStats < MiniTest::Unit::TestCase
	def test_sum_normal
		assert_equal 3, [1,2].sum
		assert_equal 6, [1,2,3].sum
	end

	def test_sum_one_element
		assert_equal 1, [1].sum
	end

	def test_sum_empty_array
		assert_equal 0, [].sum
	end

	def test_mean_normal
		assert_equal 1.5, [1,2].mean
		assert_equal 2,   [1,2,3].mean
	end

	def test_mean_one_element
		assert_equal 1, [1].mean
	end

	def test_mean_empty_array
		assert_equal 0, [].mean
	end

	def test_mean_from_wikipedia_def_page_for_stdev
		assert_equal 2.0, [2, 4, 4, 4, 5, 5, 7, 9].stdev 
	end

	def test_root_mean_square
		assert_equal Math.sqrt((1*1 + 2*2)/2.0), [1, 2].root_mean_square
		assert_equal Math.sqrt((10*10 + 243*243)/2.0), [10, 243].rms
	end

	def test_weighted_sum_one_element
		assert_equal 1, [1].weighted_sum([1])
		assert_equal 2, [1].weighted_sum([2])
	end

	def test_weighted_sum_two_elements
		assert_equal 3, 	[1, 2].weighted_sum([1, 1])
		assert_equal 22, 	[1, 4].weighted_sum([2, 5])
	end

	def test_weighted_mean_one_elements
		assert_equal 1, 	[1].weighted_mean([1])
		assert_equal 4, 	[4].weighted_mean([2])
	end

	def test_weighted_mean_two_elements
		assert_equal 1.5, 		[1, 2].weighted_mean([1, 1])
		assert_equal 22.0/7, 	[1, 4].weighted_mean([2, 5])

		assert_equal 1.5, 		[1, 2].weighted_mean()
	end
end

describe "Basic statistics" do
	describe "sum of abs" do
		it "works for simple example" do
			[1, 2, 3, -4, 5, -6].sum_of_abs.must_equal 1+2+3+4+5+6
		end
	end

	describe "sum of absolute deviations from value" do
		it "is same as sum of absolutes if the value is 0.0" do
			a = [1, 2, 3, -4, 5, -6]
			expected = a.map {|v| v.abs}.sum
			a.sum_of_abs_deviations(0.0).must_equal expected
		end

		it "works for simple example" do
			a = [1, 2, 3, -4, 5, -6]
			a.sum_of_abs_deviations(1.0).must_equal 0+1+2+5+4+7
		end
	end

	describe "rms_from_scalar" do
		it "is the same as rms if scalar is 0.0" do
			a = [1,2,3,4,5]
			a.rms_from_scalar(0.0).must_be_within_delta a.rms
		end

		it "is correct for concrete example" do
			a = [1,2]
			a.rms_from_scalar(1.5).must_equal Math.sqrt( (0.5**2 + 0.5**2)/2 )
		end
	end

	describe "squared_error" do
		it "works for simple example" do
			a = [1, 2, 3]
			b = [2, 4, 7]
			a.sum_squared_error(b).must_equal (1*1 + 2*2 + 4*4)
		end
	end

	describe "median" do
		it "works when there is a single value" do
			[1].median.must_equal 1
		end

		it "works when there are two integers, median is float" do
			[1, 2].median.must_equal 1.5
		end

		it "works when there are two floats, median is float" do
			[1.0, 2.0].median.must_equal 1.5
		end

		it "works when there are three inputs" do
			[1.0, 2.0, 3.0].median.must_equal 2.0
		end

		it "works when there are four inputs" do
			[1, 2, 3, 4].median.must_equal 2.5
		end
	end
end