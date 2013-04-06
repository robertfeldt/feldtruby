require File.join(File.dirname(__FILE__), "single_objective_problems")

class MinMulti2ObjectiveFuncOfDimensions < MinFuncOfDimensionObj
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
class MinOmniTest < MinFuncOfDimensionObj
  def domain_per_dimension
    [0.0, 6.0]
  end

  def minimum1
    @minimum1 ||= (-1 * dimensions)
  end

  def minimum2
    @minimum2 ||= (-1 * dimensions)
  end

  def calc_func1(x)
    x.map {|xi| Math.sin(Math::PI * xi)}.sum
  end

  def calc_func2(x)
    x.map {|xi| Math.cos(Math::PI * xi)}.sum
  end
end
