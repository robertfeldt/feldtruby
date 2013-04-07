require 'feldtruby/optimize/differential_evolution'
require 'feldtruby/array/basic_stats'
include FeldtRuby::Optimize

class MinimizeRMS < FeldtRuby::Optimize::Objective
	def objective_min_rms(candidate)
		candidate.rms
	end
end

class MinimizeRMSAndSum < MinimizeRMS
	def objective_min_sum(candidate)
		candidate.sum.abs
	end
end

describe "DifferentialEvolution" do
	it 'has the same logger set on itself and all sub-classes' do
		s2 = SearchSpace.new_symmetric(2, 1)
		o1 = MinimizeRMS.new
		de1 = DEOptimizer.new(o1, s2, {:verbose => false, :maxNumSteps => 1000})
		de1.logger.must_equal o1.logger
	end

	it "works for rms of small vector" do
		s2 = SearchSpace.new_symmetric(2, 1)
		o1 = MinimizeRMS.new
		de1 = DEOptimizer.new(o1, s2, {:verbose => false, :maxNumSteps => 1000})
		de1.optimize()
		# Very unlikely we get a number over 0.30 (2 elements) after 1000 steps...
		de1.best.sum.must_be :<=, 0.30
		de1.num_optimization_steps.must_equal 1000
	end

	it "works for rms and sum of small vector and with more steps" do
		s4 = SearchSpace.new_symmetric(4, 1)
		o2 = MinimizeRMSAndSum.new
		de2 = DEOptimizer.new(o2, s4, {:verbose => false, :maxNumSteps => 1234})
		de2.optimize()
		# Very unlikely we get a number over 0.40 (4 elements)...
		de2.best.sum.must_be :<=, 0.40
		de2.num_optimization_steps.must_equal 1234
	end
end

describe "DE/best/1/bin" do
	it "works for rms of small vector" do
		s2 = SearchSpace.new_symmetric(2, 1)
		o1 = MinimizeRMS.new
		de1 = DEOptimizer_Best_1_Bin.new(o1, s2, {:verbose => false, :maxNumSteps => 1000})
		de1.optimize()
		# Very unlikely we get a number over 0.30 (2 elements) after 1000 steps...
		de1.best.sum.must_be :<=, 0.30
		de1.num_optimization_steps.must_equal 1000
	end

	it "works for rms and sum of small vector and with more steps" do
		s4 = SearchSpace.new_symmetric(4, 1)
		o2 = MinimizeRMSAndSum.new
		de2 = DEOptimizer_Best_1_Bin.new(o2, s4, {:verbose => false, :maxNumSteps => 1234})
		de2.optimize()
		# Very unlikely we get a number over 0.40 (4 elements)...
		de2.best.sum.must_be :<=, 0.40
		de2.num_optimization_steps.must_equal 1234
	end
end