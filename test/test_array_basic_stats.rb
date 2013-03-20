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

describe "mean and stdev" do
	it "works for Time series 1 from http://code.google.com/p/jmotif/wiki/ZNormalization" do
    data = [2.02, 2.33, 2.99, 6.85, 9.20, 8.80, 7.50, 6.00, 5.85, 3.85, 4.85, 3.85, 2.22, 1.45, 1.34]
    data.mean.must_be_close_to 4.606667
    data.sd.must_be_close_to 2.640316
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
			a.sum_squared_error(b).must_equal(1*1 + 2*2 + 4*4)
		end
	end

	describe "median" do
		it "works when there is no value" do
			[].median.must_equal nil
		end

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

	describe "summary_stats" do
		it "gives a nice string with descriptive statistics" do
			[1,2,3,4].summary_stats.must_equal "2.5 (min = 1, max = 4, median = 2.5, stdev = 1.12)"
		end

		it "returns an empty string if there are no values" do
			[].summary_stats.must_equal ""
		end
	end

	describe "quantile- and quartile-related functionality" do
		it "can calc quantiles, quartiles and IQR for the set used as example for even-numbered sequence for quantiles on Wikipedia" do
			seq = [3, 6, 7, 8, 8, 10, 13, 15, 16, 20]
			seq.quartiles.must_equal [7.25, 9, 14.5]
			seq.quantiles.must_equal [3, 7.25, 9, 14.5, 20]
			seq.inter_quartile_range.must_equal (14.5-7.25)
		end

		it "can calc quantiles, quartiles and IQR for the set used as example for odd-numbered sequence for quantiles on Wikipedia" do
			seq = [3, 6, 7, 8, 8, 9, 10, 13, 15, 16, 20]
			seq.quartiles.must_equal [7.5, 9, 14]
			seq.quantiles.must_equal [3, 7.5, 9, 14, 20]
			seq.inter_quartile_range.must_equal 6.5
		end

		it "can calc quantiles, quartiles and IQR for the set used as example for quartiles on Wikipedia" do
			seq = [6, 47, 49, 15, 42, 41, 7, 39, 43, 40, 36]
			
			seq.quartiles.must_equal [25.5, 40, 42.5]
			seq.quantiles.must_equal [6, 25.5, 40.0, 42.5, 49]
			seq.inter_quartile_range.must_equal 17.0
		end
	end
end