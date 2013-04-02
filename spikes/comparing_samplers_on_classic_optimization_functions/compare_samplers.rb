$: << "lib"
$: << "../lib"
require 'feldtruby/optimize/differential_evolution'

# Compare different samplers and their effect on the quality of evolved 
# solutions.

$NumSteps = (ARGV[0] && ARGV[0] =~ /^\d+/) ? ARGV[0].to_i : 10_000

NumSteps1 = [1_000, 5_000, 10_000, 25_000]
NumSteps2 = [5_000, 10_000, 25_000, 50_000]

#NumSteps = NumSteps1
NumSteps = NumSteps2

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

#SamplerRadiuses = SamplerRadiuses1
SamplerRadiuses = SamplerRadiuses2

NumRepetitionsPerSampler = 100

# This is Lévi function number 13 as stated on the page:
#  http://en.wikipedia.org/wiki/Test_functions_for_optimization
# It has a global minima at f(1,1) = 0. -10 <= x,y <= 10
class MinLeviFunctionNum13 < FeldtRuby::Optimize::Objective
  TwoPi = 2*Math::PI
  ThreePi = 3*Math::PI

  def objective_min_levi13(candidate)
    x, y = candidate[0], candidate[1]
    sin_3pi_x = Math.sin(ThreePi * x)
    sin_3pi_y = Math.sin(ThreePi * y)
    sin_2pi_y = Math.sin(TwoPi * y)
    x_min1 = x - 1.0
    y_min1 = y - 1.0

    (sin_3pi_x * sin_3pi_x) + 
      (x_min1 * x_min1) * (1 + (sin_3pi_y * sin_3pi_y)) +
      (y_min1 * y_min1) * (1 + (sin_3pi_y * sin_2pi_y))
  end
end

# This is Beale's function as stated on the page:
#  http://en.wikipedia.org/wiki/Test_functions_for_optimization
# It has a global minima at f(3,0.5) = 0. -4.5 <= x,y <= 4.5
class MinBealeFunction < FeldtRuby::Optimize::Objective
  def objective_min_beales_func(candidate)
    x, y = candidate[0], candidate[1]

    t1 = 1.5 - x + (x*y)
    t2 = 2.25 - x + (x*y*y)
    t3 = 2.625 - x + (x*y*y*y)

    (t1*t1) + (t2*t2) + (t3*t3)
  end
end

# This is Easom's function as stated on the page:
#  http://en.wikipedia.org/wiki/Test_functions_for_optimization
# It has a global minima at f(3,0.5) = 0. -4.5 <= x,y <= 4.5
class MinEasomFunction < FeldtRuby::Optimize::Objective
  def objective_min_easom_func(candidate)
    x, y = candidate[0], candidate[1]

    f1 = Math.cos(x)

    f2 = Math.cos(y)

    x_min_pi = x - Math::PI
    y_min_pi = y - Math::PI

    f3 = Math.exp(-(x_min_pi*x_min_pi + y_min_pi*y_min_pi))

    (-f1) * f2 * f3
  end
end

# EggHolder function as stated on the page:
#  http://en.wikipedia.org/wiki/Test_functions_for_optimization
class MinEggHolderFunction < FeldtRuby::Optimize::Objective
  def objective_min_eggholder(candidate)
    x, y = candidate[0], candidate[1]

    f1 = y + 47.0
    f2 = Math.sin( Math.sqrt( (y + (x/2.0) + 47.0).abs ) )
    t1 = (-f1)*f2

    f3 = Math.sin( Math.sqrt( (x - (y + 47.0)).abs ) )
    t2 = (-x) * f3

    t1 - t2
  end
end

class MinFunctionOfDimension < FeldtRuby::Optimize::Objective
  attr_accessor :dimension
  def minimum
    0.0
  end
  def min_solutions
    @min_solutions ||= ([[0.0] * dimension])
  end
end

# Sphere function as stated in the JADE paper:
#  http://150.214.190.154/EAMHCO/pdf/JADE.pdf
class MinSphere < MinFunctionOfDimension
  def objective_min_func(x)
    x.inject(0.0) do |sum, xi|
      sum + (xi*xi)
    end
  end
end

# Schwefel 2.22 function as stated in the JADE paper:
#  http://150.214.190.154/EAMHCO/pdf/JADE.pdf
class MinSchwefel2_22 < MinFunctionOfDimension
  def objective_min_func(x)
    t1 = x.inject(0.0) do |sum, xi|
      sum + xi.abs
    end

    t2 = x.inject(0.0) do |mult, xi|
      mult * xi.abs
    end

    t1 + t2
  end
end

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


Problems1 = [
  ["MinLeviFunctionNum13", 2, 10],
  ["MinBealeFunction", 2, 4.5],
  ["MinEasomFunction", 2, 100]
]

Problems2 = [
  ["MinEggHolderFunction", 2, 512]
]

#Problems = Problems1
#Problems = Problems2
Problems = Problems1 + Problems2

include FeldtRuby::Optimize

def best_individual(samplerClass, radius, objectiveKlass, numVars, dist, numSteps)

  ss = SearchSpace.new_symmetric(numVars, dist)

  objective = objectiveKlass.new

  de = DEOptimizer.new(objective, ss, {
    :verbose => true, 
    :maxNumSteps => numSteps,
    :samplerClass => samplerClass,
    :samplerRadius => radius})

  best = de.optimize()

  return best, objective.quality_of(best)

end

fh = File.open("results_comparing_samplers.csv", "w")

fh.puts "Problem,Sampler,Radius,Time,NumSteps,Q,X,Y"

Problems.each do |problem, numVars, dist|
  
  objectiveKlass = eval problem
  
  NumSteps.each do |num_steps|

    SamplerRadiuses.each do |sampler, radius|
      sampler_klass = eval "FeldtRuby::Optimize::#{sampler}"
  
      NumRepetitionsPerSampler.times do
        start = Time.now
        best, qv = best_individual sampler_klass, radius, objectiveKlass, numVars, dist, num_steps
        elapsed_time = Time.now - start
  
        s = "#{problem},#{sampler},#{radius},#{elapsed_time},#{num_steps},#{qv.value},#{best[0]},#{best[1]}"
        fh.puts s
      end
  
    end
  
  end

end

fh.close