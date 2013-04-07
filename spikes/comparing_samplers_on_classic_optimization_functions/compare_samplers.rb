$: << "lib"
$: << "../../lib"
require 'feldtruby/optimize/differential_evolution'

# Compare different samplers and their effect on the quality of evolved 
# solutions.

$NumSteps = (ARGV[0] && ARGV[0] =~ /^\d+/) ? ARGV[0].to_i : 10_000

NumSteps1 = [1_000, 5_000, 10_000, 25_000]
NumSteps2 = [5_000, 10_000, 25_000, 50_000]

NumSteps = NumSteps1
#NumSteps = NumSteps2

SamplerRadiuses1 = [
  ["PopulationSampler", 15],
  ["RadiusLimitedPopulationSampler", 5],
  ["RadiusLimitedPopulationSampler", 10],
  ["RadiusLimitedPopulationSampler", 15],
  ["RadiusLimitedPopulationSampler", 20],
  ["RadiusLimitedPopulationSampler", 25],
  ["RadiusLimitedPopulationSampler", 50],
]

SamplerRadiuses2 = (4..30).map do |radius|
  ["RadiusLimitedPopulationSampler", radius]
end + [["PopulationSampler", 15]]

SamplerRadiuses = SamplerRadiuses1
#SamplerRadiuses = SamplerRadiuses2

NumRepetitionsPerSampler = 5

# Schwefel 1.2 function as stated in the JADE paper:
#  http://150.214.190.154/EAMHCO/pdf/JADE.pdf
class MinSchwefel1_2 < MinFunctionOfDimension
  def objective_min_func(x)
    i = 0
    sum = 0.0
    while i < dimension
      j = 0
      inner_sum = 0.0
      while j <= i
        inner_sum += x[j]
        j += 1
      end
      sum += inner_sum
      i += 1
    end

    sum
  end
end

# Schwefel 2.21 function as stated in the JADE paper:
#  http://150.214.190.154/EAMHCO/pdf/JADE.pdf
class MinSchwefel2_21 < MinFunctionOfDimension
  def objective_min_func(x)
    max_so_far = x[0].abs
    (1...dimension).each do |i|
      max_so_far = x[i] if (x[i] < max_so_far)
    end
    max_so_far
  end
end

# This is the OmniTest bi-criteria test function as described in the paper:
#  Shir et al, "Enhancing Decision Space Diversity in Evolutionary Multiobjective Algorithms", 2009.
class MinOmniTest < MinFunctionOfDimension
  def objective_min_sin(x)
    x.map {|xi| Math.sin(Math::PI * xi)}.sum
  end
  def objective_min_cos(x)
    x.map {|xi| Math.cos(Math::PI * xi)}.sum
  end
end

Problems1 = [
  ["MinLeviFunctionNum13", ([[-10, 10]] * 2)],
  ["MinBealeFunction", ([[-4.5, 4.5]] * 2)],
  ["MinEasomFunction", ([[-100, 100]] * 2)]
]

Problems2 = [
  ["MinEggHolderFunction", ([[-512, 512]] * 2)]
]

Problems3 = [
  ["MinOmniTest", ([[0, 6]] * 5)]
]

#Problems = Problems1
#Problems = Problems2
Problems = Problems1 + Problems2
#Problems = Problems3

include FeldtRuby::Optimize

def best_individual(samplerClass, radius, objectiveKlass, minMaxSpec, numSteps)

  ss = SearchSpace.new_from_min_max_per_variable(minMaxSpec)

  objective = objectiveKlass.new

  de = DEOptimizer.new(objective, ss, {
    :verbose => true, 
    :maxNumSteps => numSteps,
    :samplerClass => samplerClass,
    :samplerRadius => radius})

  start = Time.now
  best = de.optimize()
  elapsed_time = Time.now - start

  return best, objective.quality_of(best), elapsed_time

end

tstr = Time.now.strftime("%y%m%d_%H%M%S")

fh = File.open("results_comparing_samplers_#{tstr}.csv", "w")

# Find the max number of vars for one of the problems
MaxNumVars = Problems.map {|p| p[1].length}.max

ColNamesForVariables = (0...MaxNumVars).map {|i| "X#{i}"}.join(",")

fh.puts "Problem,Sampler,Radius,Time,NumSteps,Q,#{ColNamesForVariables}"

Problems.each do |problem, minMaxSpec|
  
  objectiveKlass = eval problem
  
  NumSteps.each do |num_steps|

    SamplerRadiuses.each do |sampler, radius|
      sampler_klass = eval "FeldtRuby::Optimize::#{sampler}"
  
      NumRepetitionsPerSampler.times do
        best, qv, elapsed_time = best_individual sampler_klass, radius, objectiveKlass, minMaxSpec, num_steps
  
        best_str = best.to_a.map {|xi| xi.to_s}.join(",")

        s = "#{problem},#{sampler},#{radius},#{elapsed_time},#{num_steps},#{qv.value},#{best_str}"
        fh.puts s
      end
  
    end
  
  end

end

fh.close