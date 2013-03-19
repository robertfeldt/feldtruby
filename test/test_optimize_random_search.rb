require 'feldtruby/optimize/random_search'
require 'feldtruby/array/basic_stats'

class TestRandomSearcher < MiniTest::Unit::TestCase
	def setup
		@s2 = FeldtRuby::Optimize::SearchSpace.new_symmetric(2, 1)
		@s4 = FeldtRuby::Optimize::SearchSpace.new_symmetric(4, 1)

		@o1 = MinimizeRMS.new
		@o2 = MinimizeRMSAndSum.new

		@rs1 = FeldtRuby::Optimize::RandomSearcher.new(@o1, @s2, {:verbose => false, :maxNumSteps => 1000})
		@rs2 = FeldtRuby::Optimize::RandomSearcher.new(@o2, @s4, {:verbose => false, :maxNumSteps => 2187})
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
		assert_equal 2187, @rs2.num_optimization_steps
	end
end