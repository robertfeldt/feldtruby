require 'feldtruby/optimize/problems/single_objective_problems'

class MinMultiObjectiveFunc < MinContinousFunction
  # Known minimum (or nil if not known). Default is at 0.0.
  def minimum
    0.0
  end

  # Known optima that gives the minimum value. Default is that it is at 0,...,0.
  def min_solutions
    @min_solutions ||= ([[0.0] * dimensions])
  end

  def num_objective_functions
    raise NotImplementedError
  end
end

class MinMulti2ObjectiveFuncOfDimensions < MinMultiObjectiveFunc
  include MinFuncOfDimensionObj
  
  def num_objective_functions
    2
  end

  def minimum1
    0.0
  end

  def minimum2
    0.0
  end

  # Known optima that gives the minimum value.
  def min_solutions
    @min_solutions ||= ([[0.0] * dimension])
  end

  def objective_min_func1(x)
    calc_func1(x) - minimum1
  end

  def objective_min_func2(x)
    calc_func2(x) - minimum2
  end

  def calc_func1(x)
    raise NotImplementedError
  end

  def calc_func2(x)
    raise NotImplementedError
  end
end


# This is the OmniTest bi-criteria test function as described in the paper:
#  Shir et al, "Enhancing Decision Space Diversity in Evolutionary Multiobjective Algorithms", 2009.
# They used dimensions == 5.
class MinOmniTest < MinMulti2ObjectiveFuncOfDimensions
  def domain_per_dimension
    [0.0, 6.0]
  end

  def minimum1
    @minimum1 ||= (-1 * dimensions)
  end

  def minimum2
    @minimum2 ||= (-1 * dimensions)
  end

  PI = Math::PI

  def calc_func1(x)
    x.map {|xi| Math.sin(PI * xi)}.sum
  end

  def calc_func2(x)
    x.map {|xi| Math.cos(PI * xi)}.sum
  end
end
