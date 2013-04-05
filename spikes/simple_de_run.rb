$: << "lib"
$: << "../lib"
require 'feldtruby/optimize/differential_evolution'

$NumSteps = (ARGV[0] && ARGV[0] =~ /^\d+/) ? ARGV[0].to_i : 10_000
$LC = ((ARGV[1] || ARGV[0]) == "EventLogger") ? FeldtRuby::EventLogger : FeldtRuby::Logger

class MinimizeRMS < FeldtRuby::Optimize::Objective
  def objective_min_rms(candidate)
    candidate.rms
  end
end

class MinimizeRMSAndSum < MinimizeRMS
  def objective_min_sum(candidate)
    candidate.sum.abs
  end

  def new_default_logger
    $LC.new(STDOUT)
  end
end

include FeldtRuby::Optimize

s4 = SearchSpace.new_symmetric(4, 1)

o2 = MinimizeRMSAndSum.new

de = DEOptimizer.new(o2, s4, {:verbose => true, :maxNumSteps => $NumSteps})

de.optimize()