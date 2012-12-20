require 'feldtruby/optimize/objective'
require 'feldtruby/array'

require 'pp'

class SingleObjective1 < FeldtRuby::Optimize::Objective
	# Sum of candidate vector of values should be small
	def objective_min_small_sum(candidate)
		candidate.sum
	end
end

class TestSingleObjective < MiniTest::Unit::TestCase
	def setup
		@o = SingleObjective1.new
	end

	def test_has_one_aspect
		assert_equal 1, @o.num_aspects
	end

	def test_quality_value
		assert_equal 1, 	@o.quality_value([1])
		assert_equal 3, 	@o.quality_value([1, 2])
		assert_equal( -42, 	@o.quality_value([1, 2, -45]) )
	end
end

class TwoMinObjectives1 < FeldtRuby::Optimize::Objective
	def objective_min_distance_between(candidate)
		candidate.distance_between_elements.sum
	end
	def objective_min_sum(candidate)
		candidate.sum
	end
end

class TestTwoObjectives < MiniTest::Unit::TestCase
	def setup
		@o = TwoMinObjectives1.new
	end
	def test_has_two_aspects
		assert_equal 2, @o.num_aspects		
	end
	def test_global_min_values_per_aspect
		assert_equal [Float::INFINITY, Float::INFINITY], @o.global_min_values_per_aspect
	end
	def test_global_max_values_per_aspect
		assert_equal [-Float::INFINITY, -Float::INFINITY], @o.global_max_values_per_aspect
	end
	def test_update_global_mins_and_maxs
		@o.update_global_mins_and_maxs([1,2])
		assert_equal [1,2], @o.global_min_values_per_aspect
		assert_equal [1,2], @o.global_max_values_per_aspect

		@o.update_global_mins_and_maxs([1,3])
		assert_equal [1,2], @o.global_min_values_per_aspect
		assert_equal [1,3], @o.global_max_values_per_aspect

		@o.update_global_mins_and_maxs([0,8])
		assert_equal [0,2], @o.global_min_values_per_aspect
		assert_equal [1,8], @o.global_max_values_per_aspect
	end
	def test_sub_objective_values
		assert_equal [1,3], @o.sub_objective_values([1,2])
		assert_equal [3,7], @o.sub_objective_values([1,2,4])
		assert_equal [4,8], @o.sub_objective_values([1,2,5])
	end
	def test_qv_mwgr
		@o.update_global_mins_and_maxs([0, 0])
		@o.update_global_mins_and_maxs([1, 3])
		assert_equal 0.0, @o.qv_mwgr([1,2])
		assert_equal 1.0, @o.qv_mwgr([0,0])
	end
	def test_qv_mwgr_complex
		# Set first values => fitness is always zero
		assert_equal 0.0, @o.qv_mwgr([1,2,3])
		# Now we come with a worse candidate => still zero
		assert_equal 0.0, @o.qv_mwgr([1,2,5])
		# But now the previous value is the best candidate we have seen so gets maximum quality value, 2 aspects * 1.0 per aspect
		assert_equal 1.0, @o.qv_mwgr([1,2,3])
		# The previous worst is still the worst
		assert_equal 0.0, @o.qv_mwgr([1,2,5])
		# And now some complex ones that are between the prev best and worst
		assert_equal( ((4.0 - 3.0)/(4-2) + (8.0 - 7)/(8-6))/2, @o.qv_mwgr([1,2,4]) )
		assert_equal( ((4.0 - 3.5)/(4-2) + (8.0 - 7.5)/(8-6))/2, @o.qv_mwgr([1,2,4.5]) )
		# Now extend the global best with a new best
		assert_equal 1.0, @o.qv_mwgr([1,2,2]) # new global min = [1, 5] and max the same at [4, 8]
		# And the in between candidates now have new values based on the new mins
		assert_equal( ((4.0 - 3.0)/(4-1) + (8.0 - 7)/(8-5))/2, @o.qv_mwgr([1,2,4]) )
		assert_equal( ((4.0 - 3.5)/(4-1) + (8.0 - 7.5)/(8-5))/2, @o.qv_mwgr([1,2,4.5]) )
	end
end

describe "Objective" do
	before do
		@o = SingleObjective1.new
		@o2 = TwoMinObjectives1.new
		@c = [1,2,3]
	end

	it "attaches quality value to an evaluated object" do
		qv = @o.quality_value(@c)
		@c._quality_value.must_equal qv
		@c._objective.must_equal @o
	end

	it "overwrites quality value if evaluated again with another objective" do
		@o.quality_value(@c)
		qv2 = @o2.quality_value(@c)
		@c._quality_value.must_equal qv2
		@c._objective.must_equal @o2
	end

	it "is re-evaluated if the objective has changed since original evaluation" do
		qv = @o2.quality_value(@c)
		@o2.quality_value([1,2,3,4,5]) # Higher sum so max updated
		qvnew = @c._quality_value
		qvnew.wont_equal qv
	end

	describe "objects that have not been evaluated" do
		it "has not attached quality values" do
			c = [1,2,3]
			c._quality_value.must_equal nil
		end
	end

	describe "version numbers" do
		it "has version number 0 when no evaluation has taken place" do
			@o.current_version.must_equal 0
			@o2.current_version.must_equal 0
		end

		it "never changes the version number for a single objective since ratios are not used" do
			@o.quality_value([1])
			@o.current_version.must_equal 0			
		end

		it "increases the version number each time a quality aspect of a candidate is more extreme than previously seen (when multi-objective)" do
			@o2.quality_value([1])
			@o2.current_version.must_equal 4 # Both min and max changed for two objectives => 2*2
			@o2.quality_value([2])
			@o2.current_version.must_equal 5 # New max values for sum objective => +1
			@o2.quality_value([1,2])
			@o2.current_version.must_equal 7 # New max values for both objectives => +2
			@o2.quality_value([0])
			@o2.current_version.must_equal 8 # New min value for sum objective => +1
			@o2.quality_value([-1])
			@o2.current_version.must_equal 9 # New min value for sum objective => +1
			@o2.quality_value([-2])
			@o2.current_version.must_equal 10 # New min value for sum objective => +1
			@o2.quality_value([1,2,3])
			@o2.current_version.must_equal 12 # New max for both objectives => +1
		end
	end
end