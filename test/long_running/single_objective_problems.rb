require 'feldtruby/optimize/search_space'

# Objective for minimizing a function which is parameterized on a dimension
# parameter.
class MinFuncOfDimensionObj < FeldtRuby::Optimize::Objective
  attr_accessor :dimensions

  # Domain (min, max) per dimension. Override this (or just override 
  # search_space directly) so that a typical/valid search space can be created.
  def domain_per_dimension
    raise NotImplementedError
  end

  # Create a valid search space. Default is to use the domain_per_dimension
  # a dimension number of times.
  def search_space
    mins_maxs = [domain_per_dimension] * self.dimensions
    FeldtRuby::Optimize::SearchSpace.new_from_min_max_per_variable mins_maxs
  end
end

class MinSingleObjectiveFuncOfDimensions < MinFuncOfDimensionObj
  # Known minimum (or nil if not known).
  def minimum
    0.0
  end

  # Known optima that gives the minimum value.
  def min_solutions
    @min_solutions ||= ([[0.0] * dimension])
  end

  def objective_min_func(x)
    calc_func(x) - minimum
  end

  # Subclasses must implement this which is the function to be minimized.
  def calc_func(x)
    raise NotImplementedError
  end
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