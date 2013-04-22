require 'feldtruby/optimize'
require 'feldtruby/float'
require 'feldtruby/optimize/sub_qualities_comparators'
require 'feldtruby/logger'
require 'feldtruby/float'
require 'feldtruby/annotations'
require 'feldtruby/json'

# Make all Ruby objects Annotateable so we can attach information to the 
# individuals being optimized.
class Object
  include FeldtRuby::Annotateable
end

module FeldtRuby::Optimize

# An Objective maps candidate solutions to qualities so they can be compared and
# ranked. 
#
# One objective can have one or more sub-objectives, called goals. Each goal
# is specified as a separate method and its name indicates if the returned
# Numeric should be minimized or maximized. To create your own objective
# you subclass and add instance methods named as 
#   goal_min_qualityAspectName (for a goal value to be minimized), or 
#   goal_max_qualityAspectName (for a goal value to be minimized).
#
# An objective keeps track of the min and max value that has been seen so far
# for each goal.
# An objective has version numbers to indicate the number of times a new min or max
# value has been identified for a goal.
#
# This base class uses weigthed sum as the quality mapper and number comparator
# as the comparator. But the mapper and comparator to be used can, of course,
# be changed.
class Objective
  include FeldtRuby::Logging

  # Current version of this objective. Is updated when the min or max values 
  # for a sub-objective has been updated or when the weights are changed. 
  # Candidates are always compared based on the latest version of an objective. 
  attr_accessor :current_version

  attr_reader :global_min_values_per_goal, :global_max_values_per_goal

  def initialize(qualityAggregator = MeanWeigthedGlobalRatios.new, #WeightedSumAggregator.new, 
    comparator = LowerAggregateQualityIsBetterComparator.new)

    # A quality aggregator maps the goal values of a candidate to a single number.
    @aggregator = qualityAggregator
    @aggregator.objective = self

    # A comparator compares two or more candidates and ranks them based on their
    # qualities.
    @comparator = comparator
    @comparator.objective = self

    self.current_version = 0

    # We set all mins to INFINITY. This ensures that the first value seen will
    # be smaller, and thus set as the new min.
    @global_min_values_per_goal = [Float::INFINITY] * num_goals

    # We set all maxs to -INFINITY. This ensures that the first value seen will
    # be larger, and thus set as the new max.
    @global_max_values_per_goal = [-Float::INFINITY] * num_goals

    setup_logger_and_distribute_to_instance_variables()

    # An array to keep the best object per goal.
    @best_objects = Array.new

  end

  # Return the number of goals of this objective.
  def num_goals
    @num_goals ||= goal_methods.length
  end

  # Return the names of the goal methods.
  def goal_methods
    @goal_methods ||= self.methods.select {|m| is_goal_method?(m)}
  end

  # Return true iff the goal method with the given index is a minimizing goal.
  def is_min_goal?(index)
    (@is_min_goal ||= (goal_methods.map {|m| is_min_goal_method?(m)}))[index]
  end

  # Return true iff the method with the given name is a goal method.
  def is_goal_method?(methodNameAsSymbolOrString)
    (methodNameAsSymbolOrString.to_s =~ /^(goal|objective)_(min|max)_([\w_]+)$/) != nil
  end

  # Return true iff the method with the given name is a goal method.
  def is_min_goal_method?(methodNameAsSymbolOrString)
    (methodNameAsSymbolOrString.to_s =~ /^(goal|objective)_min_([\w_]+)$/) != nil
  end

  # The candidate objects can be mapped to another object before we call the goal
  # methods to calc the quality values. Default is no mapping but subclasses
  # can override this for more complex evaluation schemes.
  def map_candidate_to_object_to_be_evaluated(candidate)
    candidate
  end

  # Weights is a map from goal method names to a number that represents the
  # weight for that goal. Default is to set all weights to 1.
  def weights
    @weights ||= ([1] * num_goals)
  end

  # Set the weights given a hash mapping each goal method name to a number.
  # The mapper and/or comparator can use the weights in their calculations.
  def weights=(goalNameToNumberHash)

    raise "Must be same number of weights as there are goals (#{num_aspects}), but is #{weights.length}" unless weights.length == num_goals

    weights = goal_methods.map {|gm| goalNameToNumberHash[gm]}

    logger.log_value :objective_weights_changed, 
      {"New weights" => goalNameToNumberHash}, 
      "Weights updated from #{@weights} to #{weights}"

    inc_version_number

    @weights = weights

  end

  # Return a vector of the "raw" quality values, i.e. the fitness value for each
  # goal. If we have already calculated the sub-qualities we just return them.
  # If not we calculate them.
  def sub_qualities_of(candidate, updateGlobals = true)
    # Return the sub_qualities if we already have calculated them.
    sqs = sub_qualities_if_already_calculated?(candidate)
    return sqs if sqs
    calculate_sub_qualities_of candidate, updateGlobals
  end

  # Calculate the sub-qualities from scratch, i.e. by mapping the candidate
  # to an object to be evaluated and then calculate the value of each goal.
  def calculate_sub_qualities_of(candidate, updateGlobals = true)
    obj = map_candidate_to_object_to_be_evaluated(candidate)
    sub_qualitites = goal_methods.map {|gmethod| self.send(gmethod, obj)}
    update_global_mins_and_maxs(sub_qualitites, candidate) if updateGlobals
    sub_qualitites
  end

  # Return a quality value for a given candidate and weights for the whole 
  # objective for a given candidate. Updates the best candidate if this
  # is the best seen so far.
  def quality_of(candidate, weights = self.weights)

    q = quality_in_object(candidate)
    return q if q

    sub_qualities = sub_qualities_of(candidate)

    qv = update_quality_value_of candidate, sub_qualities, weights

    update_best_candidate candidate, qv

    qv

  end

  # Invalidate the current quality object to ensure it will be recalculated
  # the next time quality_of is called with this candidate. This is needed
  # when there is a new best candidate set in an Archive, for example.
  def invalidate_quality_of(candidate)
    update_quality_value_in_object candidate, nil
  end

  # Rank candidates from best to worst. Candidates that have the same quality
  # are randomly ordered.
  def rank_candidates(candidates, weights = self.weights)
    # We first ensure all candidates have calculated sub-qualities, then we
    # call the comparator. This ensures that the gobals are already correctly
    # updated on each quality value.
    candidates.map {|c| sub_qualities_of(c, true)}

    # Now just let the comparator rank the candidates
    @comparator.rank_candidates candidates, weights
  end

  # Return true iff candidate1 is better than candidate2. Will update their
  # quality values if they are out of date.
  def is_better_than?(candidate1, candidate2)
    @comparator.is_better_than?(candidate1, candidate2)
  end

  # Return true iff candidate1 is better than candidate2. Will update their
  # quality values if they are out of date.
  def hat_compare(candidate1, candidate2)
    @comparator.hat_compare(candidate1, candidate2)
  end

  # Return true iff candidate1 is better than candidate2 for goal _index_. 
  # Will update their quality values if they are out of date.
  def is_better_than_for_goal?(index, candidate1, candidate2)
    @comparator.is_better_than_for_goal?(index, candidate1, candidate2)
  end

  # Return the aggregated quality value given sub qualities.
  def aggregated_quality(subQualities)
    @aggregator.aggregate_from_sub_qualities(subQualities, weights)
  end

  def note_end_of_optimization(optimizer)
    logger.log_data :objective_optimization_ends, {
      "Best object, aggregated" => @best_candidate,
      "Quality of best object" => @best_quality_value,
      "Version" => current_version,
      "Comparator" => @comparator,
      "Aggregator" => @aggregator,
      "Best objects per goal" => @best_objects
    }, "Objective: Report at end of optimization", true
  end

  attr_reader :best_candidate

  private

  def update_quality_value_of(candidate, subQualities, weights)
    qv = @aggregator.make_quality_value subQualities, candidate, self
    update_quality_value_in_object candidate, qv
  end

  def update_best_candidate candidate, qv
    if @best_candidate == nil || (qv.value < @best_quality_value.value)
      set_new_best_candidate candidate, qv
    end
  end

  def set_new_best_candidate candidate, qualityValue

    @best_candidate = candidate
    @best_quality_value = qualityValue

    logger.log_data :objective_new_best_candidate, {
      :candidate => candidate,
      :quality_value => qualityValue
    }, "Objective: New best ever found", true

  end

  def inc_version_number

    new_version = self.current_version + 1

    logger.log_value :objective_version_number, new_version, 
      "New version of objective: version = #{new_version}"

    self.current_version = new_version

  end

  # Update the min and max values for each goal in case the values in the
  # supplied array are outside the previously seen min and max.
  def update_global_mins_and_maxs subQualityValues, candidate
    subQualityValues.each_with_index do |sqv,i| 
      update_global_min_and_max(i, sqv, candidate)
    end
  end

  # Update the global min and max for the goal method with _index_ if
  # the _qValue_ is less than or
  def update_global_min_and_max(index, qValue, candidate)
    min = @global_min_values_per_goal[index]
    max = @global_max_values_per_goal[index]

    return unless qValue

    if qValue < min

      @global_min_values_per_goal[index] = qValue

      reset_quality_scale candidate, index, :min

    end
    if qValue > max

      @global_max_values_per_goal[index] = qValue

      reset_quality_scale candidate, index, :max

    end
  end

  # Reset the quality scale if the updated min or max value
  # was the best quality value seen for the goal with given _index_.
  def reset_quality_scale(candidate, index, typeOfReset)

    is_min = is_min_goal?(index)

    if (typeOfReset == :min && is_min) || (typeOfReset == :max && !is_min)

      @best_objects[index] = candidate

      logger.log_data :objective_better_object_for_goal, {
        :better_candidate => candidate,
        :type_of_improvement => typeOfReset
        }, "Better candidate found for goal #{goal_methods[index]}"

    end

    inc_version_number

  end

  def sub_qualities_if_already_calculated?(candidate)
    qv = quality_in_object candidate
    !qv.nil? ? qv.sub_qualities : nil
  end

  # Get the hash of annotations that we have done to this object.
  def my_annotations(object)
    object._annotations[self] ||= Hash.new
  end

  def quality_in_object(object)
    my_annotations(object)[:quality]
  end

  def update_quality_value_in_object(object, qv)
    my_annotations(object)[:quality] = qv
  end
end

# A QualityAggregator converts a vector of sub-quality values (for each individual goal of
# an objective) into a single number on which the candidates can be compared.
# Not every comparator uses the aggregated value to compare candidates though,
# but the default one does.
# This default aggregator is just a sum of the individual qualities where
# max goals are negated.
class Objective::QualityAggregator
  attr_reader :objective

  def make_quality_value(subQvs, candidate, objective)
    QualityValue.new subQvs, candidate, objective
  end

  # Set the objective to use.
  def objective=(objective)
    # Calculate the signs to be used in inverting the max methods later.
    @signs = objective.goal_methods.map {|gm| objective.is_min_goal_method?(gm) ? 1 : -1}
    @objective = objective
  end

  # Aggregate an array of _sub_qualities_ into a single number given an array of weights.
  # This default class just sums the quality values regardless of the weights.
  def aggregate_from_sub_qualities subQualityValues, weights
    subQualityValues.weighted_sum(@signs)
  end
end

# A WeightedSumAggregator sums individual quality values, each multiplied with a
# weight.
class Objective::WeightedSumAggregator < Objective::QualityAggregator
  def aggregate_from_sub_qualities subQualityValues, weights
    sum = 0.0
    subQualityValues.each_with_index do |qv, i|
      sum += (qv * weights[i] * @signs[i])
    end
    sum
  end
end

# A SumOfWeightedGlobalRatios is very similar to Bentley's SWGR multi-objective
# fitness mapping scheme as described in the paper:
#  P. J. Bentley and J. P. Wakefield, "Finding Acceptable Solutions in the 
#  Pareto-Optimal Range using Multiobjective Genetic Algorithms", 1997
#  http://eprints.hud.ac.uk/4052/1/PB_%26_JPW_1997_Finding_Acceptable_Solutions.htm
# with the difference that lower values indicate better quality and we use
# mean instead of sum, and thus call it MWGR.
# It is the weighted sum of the ratios to the best so far for each goal.
# One of its benefits is that one need not sort individuals in relation to
# their peers; the aggregate fitness value is fully determined by the individual
# and the global min and max values for each objective.
class Objective::MeanWeigthedGlobalRatios < Objective::WeightedSumAggregator
  def make_quality_value(subQvs, candidate, objective)
    PercentageQualityValue.new subQvs, candidate, objective
  end

  def ratio(index, value, min, max)
    return 1000.0 if value == nil # We heavily penalize if one sub-quality could not be calculated. Max is otherwise 1.0.
    if objective.is_min_goal?(index)
      numerator = value - min
    else
      numerator = max - value
    end
    numerator.to_f.protected_division_with(max - min)
  end

  def aggregate_from_sub_qualities subQualityValues, weights
    goal_mins = objective.global_min_values_per_goal
    goal_maxs = objective.global_max_values_per_goal

    ratios = subQualityValues.map_with_index do |v, i| 
      ratio i, v, goal_mins[i], goal_maxs[i]
    end

    # We cannot reuse the superclass in calculating the weighted sum since
    # we have already taken the signs into account in the ratio method.
    sum = 0.0
    ratios.each_with_index do |r, i|
      sum += (r * weights[i])
    end

    sum / weights.sum.to_f
  end
end

# A Comparator ranks a set of candidates based on their sub-qualities.
class Objective::Comparator
  attr_accessor :objective

  def is_better_than?(c1, c2)
    hat_compare(c1, c2) == 1
  end

  def is_better_than_for_goal?(index, c1, c2)
    objective.quality_of(c1).sub_quality(index, true) < objective.quality_of(c2).sub_quality(index, true)
  end
end

# This default comparator just uses the quality value to sort the candidates, with
# lower values indicating better quality.
class Objective::LowerAggregateQualityIsBetterComparator < Objective::Comparator
  # Return an array with the candidates ranked from best to worst.
  # Candidates that cannot be distinghuished from each other are randomly ranked.
  def rank_candidates candidates, weights
    candidates.sort_by {|c| objective.quality_of(c, weights).value}
  end

  def hat_compare(c1, c2)
    # We change the order since smaller values indicates higher quality
    objective.quality_of(c2).value <=> objective.quality_of(c1).value
  end
end

# Many of the difference relations are based on first comparing the subqualities
# pairwise. We collect this common functionality into this class.
class Objective::SubqualityDominanceComparator < Objective::Comparator
  # Count how many times 
  #   num_c1dom: c1 dominates c2 in a subquality
  #   num_c2dom: c2 dominates c1 in a subquality
  #   num_eq: non of them dominates in a subquality (this is frequently 0 for most dominance relations)
  def count_dominance_per_subquality(c1, c2)
    q1, q2 = objective.quality_of(c1), objective.quality_of(c2)
    sq1, sq2 = q1.sub_qualities_as_mins, q2.sub_qualities_as_mins
    num_c1dom = num_c2dom = num_eq = 0
    sq1.length.times do |i|
      case (sq1[i] <=> sq2[i])
      when -1
        num_c1dom += 1
      when 1
        num_c2dom += 1
      else
        num_eq += 1
      end
    end
    return num_c1dom, num_c2dom, num_eq
  end

  # The dominance comparators generally never cares about weights...
  # At least not for now...
  def rank_candidates candidates, weights
    # The case with two is so common that we shortcut it
    return rank_2candidates(candidates) if candidates.length == 2
    flatten_group_ranked_candidates group_rank_candidates(candidates)
  end

  # This gives no guarantees on the order among the candidates in the same group, but
  # it is not randomized so might be bias in there. Subclasses should override if
  # they want some other guarantees.
  def flatten_group_ranked_candidates(groupRankedCandidates)
    groupRankedCandidates.flatten(1)
  end

  # This is Deb's non-dominated sorting algorithm that returns an array of the
  # classes of non-dominated candidates. Each such class is a separate array.
  def group_rank_candidates candidates
    left_to_sort = candidates.clone
    f = []
    while left_to_sort.length > 0
      f << (fk = [])
      left_to_sort.each do |ci|
        (fk << ci) unless left_to_sort.any? {|cj| is_better_than?(cj, ci)}
      end
      if fk.length == 0
        f[f.length-1] = left_to_sort
        break
      else
        left_to_sort -= fk
      end
    end
    f
  end

  # Quicker implementation when there is only two candidates to rank.
  def rank_2candidates(candidates)
    if is_better_than?(candidates[0], candidates[1])
      candidates
    else
      [candidates[1], candidates[0]]
    end
  end
end

# Include this module to get random order among candidates of similar rank
# (when they are returned from rank_candidates).
module Objective::RandomizeGroupRankedCandidates
  def flatten_group_ranked_candidates(groupRankedCandidates)
    groupRankedCandidates.map {|g| g.shuffle}.flatten(1)
  end
end

# Include this module to get order based on aggregate fitness among candidates of similar rank
# (when they are returned from rank_candidates). We assume lower aggregate quality is better.
module Objective::RandomizeGroupRankedCandidates
  def flatten_group_ranked_candidates(groupRankedCandidates)
    o = self.objective
    groupRankedCandidates.map {|g| g.sort_by {|c| o.quality_of(c).value}}.flatten(1)
  end
end

# Pareto non-dominance comparator on the subqualities.
class Objective::ParetoNonDominanceComparator < Objective::SubqualityDominanceComparator
  include Objective::RandomizeGroupRankedCandidates

  def hat_compare(c1, c2)
    num_c1dom, num_c2dom, num_eq = count_dominance_per_subquality(c1, c2)
    if num_c1dom > 0
      # Note! We return 1 to indicate that c2 is worse since minimization is the default!
      (num_c2dom == 0) ? 1 : 0
    elsif num_c2dom > 0
      # Note! We return -1 to indicate that c1 is worse since minimization is the default!
      (num_c1dom == 0) ? -1 : 0
    else
      0
    end
  end
end

# Class for representing multi-objective _sub_qualitites_ and their summary
# _value_. A quality has a version number which was the version of
# the objective when this quality was calculated. When a quality value
# is compared to another quality value they are first updated so that
# they reflect the quality of the candidate for the current version of
# the objective.
class QualityValue
  include Comparable
  include ToJsonImplementedViaDataHash

  attr_reader :sub_qualities, :objective, :candidate

  def initialize(subQvs, candidate, objective)
    @sub_qualities, @objective = subQvs, objective
    @candidate = candidate
  end

  # Return the aggregated quality value. Will always return an updated value
  # since it will be recalculated if we have the wrong version.
  def value
    return @value if @version && @version == @objective.current_version
    @version = @objective.current_version
    @value = @objective.aggregated_quality(@sub_qualities)
  end

  def <=>(other)
    return nil unless @objective == other.objective
    @objective.hat_compare(@candidate, other.candidate)
  end

  # Return the sub quality value with a given index. Can make sure maximization
  # goals are mapped as minimization goals if ensureMinimization is true.
  def sub_quality(index, ensureMinimization = false)
    return @sub_qualities[index] if !ensureMinimization || @objective.is_min_goal?(index)
    # Now we now this is a max goal that should be returned as a min goal => invert it.
    -(@sub_qualities[index])
  end

  # Returns an array with all sub_qualities mapped as minimization values, i.e.
  # the value of max goals are negated.
  def sub_qualities_as_mins
    len = sub_qualities.length
    sqmins = Array.new(len)
    len.times {|i| sqmins[i] = sub_quality(i, true)}
    sqmins
  end

  def data_to_json_hash
    {
      "id" => @candidate.object_id,
      "qv" => value,
      "qvd" => display_value,
      "subqs" => @sub_qualities,
      "candidate" => @candidate.to_a
    }
  end

  # The value to display. For this default class we just use the quality value.
  def display_value
    value
  end

  def value_to_s
    "#{display_value.to_significant_digits(4)}"
  end

  def to_s
    subqs = sub_qualities.map {|f| f ? f.to_significant_digits(3) : nil}
    # Note! We ask for the value first which guarantees that we then have a version number.
    qstr = value_to_s
    "#{qstr} (SubQs = #{subqs.inspect}, ver. #{@version})"
  end
end

class PercentageQualityValue < QualityValue
  def display_value
    (1.0 - value) * 100.0
  end
  def value_to_s
    return "N/A" if @sub_qualities.any? {|sq| sq.nil?}
    "%s%%" % display_value.to_significant_digits(6).to_s
  end
end


# Short hand for when the objective function is given as a block that should be minimized.
class ObjectiveMinimizeBlock < Objective
  def initialize(&objFunc)
    super()
    @objective_function = objFunc
  end

  def objective_min_cost_function(candidate)
    @objective_function.call(*candidate.to_a)
  end
end

# Short hand for when the objective function is given as a block that should be minimized.
class ObjectiveMaximizeBlock < Objective
  def initialize(&objFunc)
    super()
    @objective_function = objFunc
  end

  def objective_max_cost_function(candidate)
    @objective_function.call(*candidate.to_a)
  end
end

# A diversity objective often is a secondary goal and is measured relative
# to quality goals/objectives or relative to candidates in the archive.
# Thus it needs to have access to these other two objects.
class DiversityObjective < Objective
  attr_accessor :archive
  attr_accessor :quality_objective
end

# The standard diversity objective is to just use the Euclidean distance
# to the best candidate found so far.
class FeldtRuby::Optimize::EuclideanDistanceToBest < FeldtRuby::Optimize::DiversityObjective
  # Euclidean distance to best candidate. Genotype diversity.
  def goal_max_euclidean_distance_to_best(candidate)
    candidate.rms_from(archive.best)
  end
end

end