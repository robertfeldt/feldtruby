$: << "lib"
$: << "../lib"
$: << "."
require 'feldtruby/optimize/differential_evolution'
require 'test/long_running/single_objective_problems'

def best_from_de_on_objective(objective, dimensions, numSteps = 25_000, 
  verbose = true, optimizer = FeldtRuby::Optimize::DEOptimizer_Rand_1_Bin)
  objective.dimensions = dimensions if objective.respond_to?(:dimensions=)
  ss = objective.search_space
  de = optimizer.new(objective, ss, {:verbose => verbose, 
    :maxNumSteps => numSteps})

  start_time = Time.now
  best = de.optimize().to_a
  elapsed = Time.now - start_time

  return best, objective, elapsed, de
end

#best, obj, time, de = best_from_de_on_objective MinSphere.new, 30, 220_000
best, obj, time, de = best_from_de_on_objective MinEggHolder.new, nil, 15_000
File.open("archive.json", "w") {|fh| fh.puts(JSON.pretty_generate(de.archive))}