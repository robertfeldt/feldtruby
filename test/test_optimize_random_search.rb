require 'feldtruby/optimize/random_search'
require 'feldtruby/array/basic_stats'

class MinimizeRMS < FeldtRuby::Optimize::Objective
	def objective_min_rms(candidate)
		candidate.rms
	end
end

class TestRandomSearcher < MiniTest::Unit::TestCase
	def setup
		@ss = FeldtRuby::Optimize::SearchSpace.new_symmetric(2, 1)
		@o = MinimizeRMS.new
		@rs = FeldtRuby::Optimize::RandomSearcher.new(@o, @ss, {:verbose => false})
	end
	def test_random_search_for_small_vector
		@rs.optimize()
		# Very unlikely we get a number over 0.40 after 1000 steps...
		assert @rs.best.sum <= 0.40
		assert_equal 1000, @rs.num_optimization_steps
	end
end