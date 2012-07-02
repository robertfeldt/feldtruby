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
		assert_equal -42, 	@o.quality_value([1, 2, -45])
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
	def test_qv_swgr
		@o.update_global_mins_and_maxs([0, 0])
		@o.update_global_mins_and_maxs([1, 3])
		assert_equal 0.0, @o.qv_swgr([1,2])
		assert_equal 2.0, @o.qv_swgr([0,0])
	end
	def test_qv_swgr_complex
		# Set first values => fitness is always zero
		assert_equal 0.0, @o.qv_swgr([1,2,3])
		# Now we come with a worse candidate => still zero
		assert_equal 0.0, @o.qv_swgr([1,2,5])
		# But now the previous value is the best candidate we have seen so gets maximum quality value, 2 aspects * 1.0 per aspect
		assert_equal 2.0, @o.qv_swgr([1,2,3])
		# The previous worst is still the worst
		assert_equal 0.0, @o.qv_swgr([1,2,5])
		# And now some complex ones that are between the prev best and worst
		assert_equal ((4.0 - 3.0)/(4-2) + (8.0 - 7)/(8-6)), @o.qv_swgr([1,2,4])
		assert_equal ((4.0 - 3.5)/(4-2) + (8.0 - 7.5)/(8-6)), @o.qv_swgr([1,2,4.5])
		# Now extend the global best with a new best
		assert_equal 2.0, @o.qv_swgr([1,2,2]) # new global min = [1, 5] and max the same at [4, 8]
		# And the in between candidates now have new values based on the new mins
		assert_equal ((4.0 - 3.0)/(4-1) + (8.0 - 7)/(8-5)), @o.qv_swgr([1,2,4])
		assert_equal ((4.0 - 3.5)/(4-1) + (8.0 - 7.5)/(8-5)), @o.qv_swgr([1,2,4.5])
	end
end
