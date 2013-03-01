module FeldtRuby::Optimize

# A SubQualititesComparator can compare vectors of sub-qualitites for two individuals
# and rank the individuals based on if one is better (or dominates) the other.
class SubQualitiesComparator
  def initialize(objective)
    @objective = objective
  end

  # Compare two sub-quality vectors and return
  #   -1 if the first one dominates the other one
  #    0 if none of them dominate the other
  #    1 if the second one dominates the first one
  def compare_sub_qualitites(subQualitites1, subQualitites2)
    raise NotImplementedError
  end

  def compare_candidates(candidate1, candidate2)
    sq1, sq2 = @objective.sub_qualities_of(candidate1), @objective.sub_qualities_of(candidate2)
    compare_sub_qualitites sq1, sq2
  end

  # True iff the first dominates the second sub-quality vectors.
  def first_dominates?(subQualitites1, subQualitites2)
    compare_sub_qualitites(subQualitites1, subQualitites2) == -1
  end

  # True iff the second dominates the first sub-quality vectors.
  def second_dominates?(subQualitites1, subQualitites2)
    compare_sub_qualitites(subQualitites1, subQualitites2) == 1
  end
end

# Epsilon-distance non-dominance comparator. Default epsilon is 0.0 which
# gives the standard non-dominance comparator.
class EpsilonNonDominance < SubQualitiesComparator
  def initialize(objective, epsilon = 0.0)
    super(objective)
    @epsilon = epsilon
  end

  # Map hat operator to paired sub-quality values.
  def map_hat_operator(sq1, sq2)
    # NOTE! Below we assume that all sub-objectives should be minimized. If not we should
    # change the sign of the hat operator return value!
    sq1.zip(sq2).map do |sqv1, sqv2|
      if (sqv1 - sqv2).abs > @epsilon
        (sqv1 < sqv2) ? -1 : 1
      else
        0
      end
    end
  end

  def compare_sub_qualitites(subQualitites1, subQualitites2)
    hat_values = map_hat_operator(subQualitites1, subQualitites2)
    num_1_better = num_2_better = 0
    hat_values.each do |hv|
      if hv == -1
        num_1_better += 1
      elsif hv == 1
        num_2_better += 1
      end
    end
    if num_1_better > 0
      (num_2_better == 0) ? -1 : 0
    else
      (num_2_better > 0) ? 1 : 0
    end
  end
end

end