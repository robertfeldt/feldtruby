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
end