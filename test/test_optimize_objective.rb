require 'feldtruby/optimize/objective'
require 'feldtruby/array/basic_stats'

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

class TwoObjectives1 < FeldtRuby::Optimize::Objective
	def objective_min_small_distance_between(candidate)
		candidate.distance_between.sum
	end
	def objective_max_sum(candidate)
		candidate.sum
	end
end

class TestTwoObjectives < MiniTest::Unit::TestCase
end
