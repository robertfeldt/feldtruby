require 'minitest/spec'
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

	describe "ranks_by" do
		it "works when element to rank by is first and we prepend the ranks" do
			[[2.5, :a], [1.5, :b], [0.3, :c]].ranks_by(true) {|v| v.first}.must_equal [
				[1, 2.5, :a], [2, 1.5, :b], [3, 0.3, :c]
			]
		end		

		it "works when element to rank by is second and we append the ranks" do
			[[:a, 2.5], [:c, 0.3], [:b, 1.5]].ranks_by(false) {|v| v[1]}.must_equal [
				[:a, 2.5, 1], [:c, 0.3, 3], [:b, 1.5, 2]
			]
		end		
	end

	describe "add_unless_there" do
		it "adds an element when array is empty" do
			[].add_unless_there(1).must_equal [1]
		end
	
		it "adds an element when array is NOT empty" do
			[1,2].add_unless_there(3).must_equal [1,2,3]
		end
	
		it "does nothing when element is already in array" do
			[1,2,3].add_unless_there(3).must_equal [1,2,3]
		end
	end

	describe "count_elements" do
		it "counts elements when only two of them" do
			counts = [2,1,2,2,1,1,2,1,2].counts
			counts.keys.sort.must_equal [1,2]
			counts[1].must_equal 4
			counts[2].must_equal 5
		end

		it "counts elements when many different elements and of different types" do
			counts = [:a, :b, :b, "c", "d", 5, "c", 5, "c", "d", 5, "d", 5, 5, "d"].counts
			counts[:a].must_equal 1
			counts[:b].must_equal 2
			counts["c"].must_equal 3
			counts["d"].must_equal 4
			counts[5].must_equal 5
		end
	end

	describe "sample" do
		it "only samples within the array" do
			d = (1..100).to_a
			100.times { d.include?(d.sample).must_equal(true) }
		end
	end
end
