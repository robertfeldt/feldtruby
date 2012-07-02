require 'feldtruby/optimize/random_search'
require 'feldtruby/array/basic_stats'

class MinimizeRMS < FeldtRuby::Optimize::Objective
	def objective_min_rms(candidate)
		candidate.rms
	end
end

class MinimizeRMSAndSum < MinimizeRMS
	def objective_min_sum(candidate)
		candidate.sum
	end
end

class TestRandomSearcher < MiniTest::Unit::TestCase
	def setup
		@s2 = FeldtRuby::Optimize::SearchSpace.new_symmetric(2, 1)
		@s3 = FeldtRuby::Optimize::SearchSpace.new_symmetric(2, 1)

		@o1 = MinimizeRMS.new
		@o2 = MinimizeRMSAndSum.new

		@rs1 = FeldtRuby::Optimize::RandomSearcher.new(@o1, @s2, {:verbose => false})
		@rs2 = FeldtRuby::Optimize::RandomSearcher.new(@o2, @s3, {:verbose => false, :maxNumSteps => 1546})
	end

	def test_random_search_for_small_vector_with_rms
		@rs1.optimize()
		# Very unlikely we get a number over 0.40 (2 elements) after 1000 steps...
		assert @rs1.best.sum <= 0.40
		assert_equal 1000, @rs1.num_optimization_steps
	end

	def test_random_search_for_small_vector_with_rms_and_sum_for_more_steps
		@rs2.optimize()
		# Very unlikely we get a number over 0.40 (3 elements)...
		assert @rs2.best.sum <= 0.60
		assert_equal 1546, @rs2.num_optimization_steps
	end
end