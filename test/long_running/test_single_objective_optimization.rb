require File.join(FeldtRubyLongTestDir, "single_objective_problems")
require 'feldtruby/optimize/differential_evolution'
include FeldtRuby::Optimize

module MiniTest::Assertions
  # Assert that _bestSolution_ is close to at least one of the solutions that minimize
  # the _objective_. We use the minimum RMS distance to the solutions, which should
  # be close to zero for at least one solution.
  def assert_close_to_one_solution(objective, bestSolution, precision = 0.01, msg = nil)
    rmss = objective.min_solutions.map do |min_solution|
      bestSolution.to_a.rms_from(min_solution)
    end
    # The minimum RMS to a solution must be close to zero.
    rmss.min.must_be_close_to 0.0, precision
  end
end

module MiniTest::Expectations
  infect_an_assertion :assert_close_to_one_solution, :must_be_close_to_one_solution_of
end

# Note! We have set the numSteps below so that DEOptimizer_Rand_1_Bin can converge
# to a solution. However, for most of these optimization problems 
# DEOptimizer_Best_1_Bin converges much faster, and can thus be used.

def best_from_de_on_objective(objective, dimensions, numSteps = 25_000, 
  verbose = false, optimizer = FeldtRuby::Optimize::DEOptimizer_Rand_1_Bin)
  objective.dimensions = dimensions if objective.respond_to?(:dimensions=)
  ss = objective.search_space
  de = optimizer.new(objective, ss, {:verbose => verbose, 
    :maxNumSteps => numSteps})

  start_time = Time.now
  best = de.optimize().to_a
  elapsed = Time.now - start_time

  val = objective.calc_func(best)
  val.must_be_close_to objective.minimum
  val.must_be :>, objective.minimum

  return best, objective, elapsed
end

describe "Sphere function" do
  it 'can optimize the Sphere function in 3 dimensions' do
    best, obj, time = best_from_de_on_objective MinSphere.new, 3, 12_000
    best.must_be_close_to_one_solution_of obj
    time.must_be :<, 1.5
  end

  it 'can optimize the Sphere function in 10 dimensions' do
    best, obj, time = best_from_de_on_objective MinSphere.new, 10, 60_000
    best.must_be_close_to_one_solution_of obj
    time.must_be :<, 7.5
  end

#  it 'can optimize the Sphere function in 30 dimensions' do
#    best, obj, time = best_from_de_on_objective MinSphere.new, 30, 220_000
#    time.must_be :<, 28.0
#    # We don't test closeness since it might take very long for 30D to get close on all dimensions.
#  end
end

describe "Levi13 function" do
  it 'can optimize the Levi13 function' do
    best, obj, time = best_from_de_on_objective MinLevi13.new, nil, 7_500
    best.must_be_close_to_one_solution_of obj
    time.must_be :<, 1.0
  end
end

describe "Beale function" do
  it 'can optimize the Beale function' do
    best, obj, time = best_from_de_on_objective MinBeale.new, nil, 7_500
    best.must_be_close_to_one_solution_of obj
    time.must_be :<, 1.0
  end
end

describe "Easom function" do
  it 'can optimize the Easom function' do
    best, obj, time = best_from_de_on_objective MinBeale.new, nil, 10_000, false, FeldtRuby::Optimize::DEOptimizer_Best_1_Bin
    best.must_be_close_to_one_solution_of obj
    time.must_be :<, 1.5
  end
end

describe "EggHolder function" do
  it 'can optimize the Eggholder function' do
    best, obj, time = best_from_de_on_objective MinEggHolder.new, nil, 10_000, false, FeldtRuby::Optimize::DEOptimizer_Best_1_Bin
    best.must_be_close_to_one_solution_of obj
    time.must_be :<, 1.5
  end
end

describe "Schwefel 2.22 function" do
  it 'can optimize the Schwefel 2.22 function in 3 dimensions' do
    best, obj, time = best_from_de_on_objective MinSchwefel2_22.new, 3, 12_000
    best.must_be_close_to_one_solution_of obj
    time.must_be :<, 1.5
  end
end