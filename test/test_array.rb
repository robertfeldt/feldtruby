require 'feldtruby/array'

class TestFeldtRubyArray < MiniTest::Unit::TestCase
	def test_distance_between_elements_normal_cases
		assert_equal [1], 		[1, 2].distance_between_elements
		assert_equal [1, 2], 	[1, 2, 4].distance_between_elements
		assert_equal [3, 11], 	[-1, 2, 13].distance_between_elements
	end

	def test_distance_elements_when_one_element
		assert_equal [], [1].distance_between_elements
	end

	def test_distance_elements_empty_array
		assert_equal nil, [].distance_between_elements
	end

	def test_weighted_sum_one_element
		assert_equal 1, [1].weighted_sum([1])
		assert_equal 2, [1].weighted_sum([2])
	end

	def test_weighted_sum_two_elements
		assert_equal 3, 	[1, 2].weighted_sum([1, 1])
		assert_equal 22, 	[1, 4].weighted_sum([2, 5])
	end
end
