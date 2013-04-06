require File.join(FeldtRubyLongTestDir, "single_objective_problems")
require 'feldtruby/optimize/differential_evolution'
include FeldtRuby::Optimize

describe "Sphere function" do
  def best_from_de_on_sphere(dimensions, numSteps = 25_000, verbose = false)
    sphere = MinSphere.new
    sphere.dimensions = dimensions
    ss = sphere.search_space
    de = DEOptimizer.new(sphere, ss, {:verbose => verbose, 
      :maxNumSteps => numSteps})
    best = de.optimize().to_a
    return best, sphere
  end

  it 'can optimize the Sphere function in 3 dimensions' do
    best, obj = best_from_de_on_sphere 3, 15_000

    val = obj.calc_func(best)
    val.must_be_close_to 0.0
    val.must_be :>, 0.0

    best.each do |xi|
      xi.must_be_close_to 0.0
    end
  end

  it 'can optimize the Sphere function in 10 dimensions' do
    best, obj = best_from_de_on_sphere 10, 60_000

    val = obj.calc_func(best)
    val.must_be_close_to 0.0
    val.must_be :>, 0.0

    best.each do |xi|
      xi.must_be_close_to 0.0
    end
  end

  it 'can optimize the Sphere function in 30 dimensions' do
    best, obj = best_from_de_on_sphere 30, 220_000

    val = obj.calc_func(best)
    val.must_be_close_to 0.0
    val.must_be :>, 0.0
  end
end
