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
	def objective_min_small_distance_between(candidate)
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
		assert_equal [4,8], @o.sub_objective_values([1,2,5])
	end
	def test_qv_swgr
		@o.update_global_mins_and_maxs([0, 0])
		@o.update_global_mins_and_maxs([1, 3])
		assert_equal 0.0, @o.qv_swgr([1,2])
		assert_equal 2.0, @o.qv_swgr([0,0])
	end
	def test_qv_swgr_complex
		assert_equal 0.0, @o.qv_swgr([1,2])
	end
end
