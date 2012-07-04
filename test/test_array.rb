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

	def test_swap!
		a = (0..9).to_a

		a.swap!(0, 8)
		assert_equal 8, a[0]
		assert_equal 0, a[8]
		assert_equal 1, a[1]
		assert_equal 9, a[9]

		a.swap!(0, 9)
		assert_equal 9, a[0]
		assert_equal 0, a[8]
		assert_equal 8, a[9]
		assert_equal 2, a[2]
	end
end

describe "Array extensions" do
	describe "ranks" do
		it "works when elements are already in order" do
			[2.5, 1.5, 0.3].ranks.must_equal [1, 2, 3]
			[15, 7, 1, 0].ranks.must_equal [1, 2, 3, 4]
		end

		it "works when elements are in reverse order" do
			[0.3, 1.5, 2.5].ranks.must_equal [3, 2, 1]
			[0, 1, 7, 15].ranks.must_equal [4, 3, 2, 1]
		end

		it "works when elements are out of order" do
			[1.5, 0.5, 2.3].ranks.must_equal [2, 3, 1]
			[1, 7, 15, 0].ranks.must_equal [3, 2, 1, 4]
		end

		it "works when given an empty array" do
			[].ranks.must_equal []
		end
	end
end
