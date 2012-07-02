require 'helper'
require 'feldtruby/array/basic_stats'

class TestArrayBasicStatsSum < MiniTest::Unit::TestCase
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
end

class TestArrayBasicStatsMean < MiniTest::Unit::TestCase
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
end

class TestArrayBasicStatsStdev < MiniTest::Unit::TestCase
	def test_mean_from_wikipedia_def_page_for_stdev
		assert_equal 2.0, [2, 4, 4, 4, 5, 5, 7, 9].stdev 
	end
end
