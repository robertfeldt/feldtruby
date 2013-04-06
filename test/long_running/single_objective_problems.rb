require 'feldtruby/optimize/search_space'

class MinContinousFunction < FeldtRuby::Optimize::Objective
  # Subclasses should fix this value.
  def dimensions
    @dimensions
  end

  # Domain (min, max) per dimension. Override this (or just override 
  # search_space or domain_as_mins_maxs directly) so that a typical/valid 
  # search space can be created.
  def domain_per_dimension
    raise NotImplementedError
  end

  # For more complex domains sub-classes can override this method.
  def domain_as_mins_maxs
    [domain_per_dimension] * self.dimensions
  end

  # Create a valid search space. Default is to use the domain_per_dimension
  # a dimension number of times.
  def search_space
    FeldtRuby::Optimize::SearchSpace.new_from_min_max_per_variable domain_as_mins_maxs
  end
end

class MinSingleObjectiveFunc < MinContinousFunction
  # Known minimum (or nil if not known). Default is at 0.0.
  def minimum
    0.0
  end

  # Known optima that gives the minimum value. Default is that it is at 0,...,0.
  def min_solutions
    @min_solutions ||= ([[0.0] * dimensions])
  end

  def objective_min_func(x)
    calc_func(x) - minimum
  end

  # Subclasses must implement this which is the function to be minimized.
  def calc_func(x)
    raise NotImplementedError
  end
end

# Objectives that minimizes a function which is parameterized on a dimension
# parameter should include this module.
module MinFuncOfDimensionObj
  attr_writer :dimensions
end

class MinSingleObjectiveFuncOfDimensions < MinSingleObjectiveFunc
  include MinFuncOfDimensionObj
end

# Sphere function as stated in the JADE paper:
#  http://150.214.190.154/EAMHCO/pdf/JADE.pdf
class MinSphere < MinSingleObjectiveFuncOfDimensions
  def calc_func(x)
    x.inject(0.0) do |sum, xi|
      sum + (xi*xi)
    end
  end

  def domain_per_dimension
    [-100, 100]
  end
end

# This is Lévi function number 13 as stated on the page:
#  http://en.wikipedia.org/wiki/Test_functions_for_optimization
# It has a global minima at f(1,1) = 0. -10 <= x,y <= 10
class MinLeviFunc13 < MinSingleObjectiveFunc
  def dimensions
    2
  end

  def min_solutions
    [[1.0, 1.0]]
  end

  def domain_per_dimension
    [-10.0, 10.0]
  end

  TwoPi = 2*Math::PI
  ThreePi = 3*Math::PI

  def calc_func(candidate)
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
