require 'feldtruby/optimize'
require 'feldtruby/float'
require 'feldtruby/optimize/sub_qualities_comparators'
require 'feldtruby/logger'
require 'feldtruby/float'
require 'feldtruby/annotations'

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

	# A quality mapper maps the goal values of a candidate to a single number.
	attr_accessor :quality_mapper

	# A comparator compares two or more candidates and ranks them based on their
	# qualities.
	attr_accessor :comparator

	attr_reader :global_min_values_per_aspect, :global_max_values_per_aspect

	def initialize(qualityMapper = nil, comparator = nil)

		@quality_mapper = qualityMapper || WeightedSumQualityMapper.new
		@comparator = comparator || Comparator.new
		@quality_mapper.objective = self
		@comparator.objective = self

		self.current_version = 0

		# We set all mins to INFINITY. This ensures that the first value seen will
		# be smaller, and thus set as the new min.
		@global_min_values_per_aspect = [Float::INFINITY] * num_goals

		# We set all maxs to -INFINITY. This ensures that the first value seen will
		# be larger, and thus set as the new max.
		@global_max_values_per_aspect = [-Float::INFINITY] * num_goals

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
	# goal.
	def sub_qualities_of(candidate, updateGlobals = true)
		obj = map_candidate_to_object_to_be_evaluated(candidate)
		sub_qualitites = goal_methods.map {|gmethod| self.send(gmethod, obj)}
		update_global_mins_and_maxs(sub_qualitites, candidate) if updateGlobals
		sub_qualitites
	end

	# Return a quality value for a given candidate and weights for the whole 
	# objective for a given candidate. Updates the best candidate if this
	# is the best seen so far.
	def quality_of(candidate, weights = self.weights)

		q = quality_if_up_to_date?(candidate)
		return q if q

		sub_qualities = sub_qualities_of(candidate)

		qv = update_quality_value_of candidate, sub_qualities, weights

		update_best_candidate candidate, qv

		qv

	end

	# Rank candidates from best to worst. Updates the quality value of each
	# candidate.
	def rank_candidates(candidates, weights = self.weights)

		# Map each candidate to its sub-qualities without updating the globals.
		# We will update once for the whole set below.
		sqvss = candidates.map {|c| sub_qualities_of(c, false)}

		# Update the global mins and maxs based on the set of sub-qualities.
		# Note! This must be done once for the whole set otherwise when we later 
		# compare the cnadidates based on their quality values they
		# might be for different versions of the objective.
		sqvss.each_with_index do |sqvs, i|
			update_global_mins_and_maxs sqvs, candidates[i]
		end

		# Update the quality value of each candidate.
		sqvss.each_with_index do |sqvs, i|
			update_quality_value_of candidates[i], sqvs, weights
		end

		# Now use the comparator to rank the candidates.
		comparator.rank_candidates candidates, weights

	end

	# Return true iff candidate1 is better than candidate2. Will update their
	# quality values if they are out of date.
	def is_better_than?(candidate1, candidate2)
		quality_of(candidate1) < quality_of(candidate2)
	end

	# Return true iff candidate1 is better than candidate2 for goal _index_. 
	# Will update their quality values if they are out of date.
	def is_better_than_for_goal?(index, candidate1, candidate2)
		qv1 = quality_of(candidate1)
		qv2 = quality_of(candidate2)
		qv1.sub_quality(index, true) <= qv2.sub_quality(index, true)
	end

	def note_end_of_optimization(optimizer)
		nil
	end

	attr_reader :best_candidate

	private

	def update_quality_value_of(candidate, subQualities, weights)

		q = quality_mapper.map_from_sub_qualities(subQualities, weights)

		qv = QualityValue.new q, subQualities, candidate, self

		update_quality_value_in_object candidate, qv

	end

	def update_best_candidate candidate, qv
		if @best_candidate == nil || (qv < @best_quality_value)
			set_new_best_candidate candidate, qv
		end
	end

	def set_new_best_candidate candidate, qualityValue

		@best_candidate = candidate
		@best_quality_value = qualityValue

		logger.log_data :objective_new_best_candidate, {
			:candidate => candidate,
			:quality_value => qualityValue
		}, "New best candidate found"

	end

	def inc_version_number

		new_version = @current_version + 1

		logger.log_value :objective_version_number, new_version, 
			"New version of objective:\n#{self.to_s}"

		@current_version = new_version

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
		min = @global_min_values_per_aspect[index]
		max = @global_max_values_per_aspect[index]

		if qValue < min

			@global_min_values_per_aspect[index] = qValue

			reset_quality_scale candidate, index, :min

		end
		if qValue > max

			@global_max_values_per_aspect[index] = qValue

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
				}, "Better object found for goal #{goal_methods[index]}"

			# Reset the best object since we have a new scale
			@best_candidate = nil

		end

		inc_version_number

	end

	# Check if a candidates quality value according to this objective is
	# up to date with the latest version of the objective.
	def quality_if_up_to_date?(candidate)
		qv = quality_in_object candidate
		(!qv.nil? && qv.version == current_version) ? qv : nil
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

# A QualityMapper maps a vector of sub-quality values (for each individual goal of
# an objective) into a single number on which the candidates can be compared.
class Objective::QualityMapper
	attr_reader :objective

	def objective=(objective)
		# Calculate the signs to be used in inverting the max methods later.
		@signs = objective.goal_methods.map {|gm| objective.is_min_goal_method?(gm) ? 1 : -1}
		@objective = objective
	end

	# Map an array of _sub_qualities_ to a single number given an array of weights.
	# This default class just sums the quality values regardless of the weights.
	def map_from_sub_qualities subQualityValues, weights
		subQualityValues.weighted_sum(@signs)
	end
end

# A WeightedSumMapper sums individual quality values, each multiplied with a
# weight.
class Objective::WeightedSumQualityMapper < Objective::QualityMapper
	def map_from_sub_qualities subQualityValues, weights
		sum = 0.0
		subQualityValues.each_with_index do |qv, i|
			sum += (qv * weights[i] * @signs[i])
		end
		sum
	end
end

# A SumOfWeightedGlobalRatios implements Bentley's SWGR multi-objective
# fitness mapping scheme as described in the paper:
#  P. J. Bentley and J. P. Wakefield, "Finding Acceptable Solutions in the 
#  Pareto-Optimal Range using Multiobjective Genetic Algorithms", 1997
#  http://eprints.hud.ac.uk/4052/1/PB_%26_JPW_1997_Finding_Acceptable_Solutions.htm
# It is a weighted sum of the ratios to the best so far for each goal.
# One of its benefits is that one need not sort individuals in relation to
# their peers; the aggregate fitness value is fully determined by the individual
# and the global min and max values for each objective.
class Objective::SumOfWeigthedGlobalRatiosMapper < Objective::WeightedSumQualityMapper
	def ratio(index, value, min, max)
		return 0.0 if value == nil
		if objective.is_min_aspect?(index)
			numerator = max - value
		else
			numerator = value - min
		end
		numerator.to_f.protected_division_with(max - min)
	end

	def map_from_sub_qualities subQualityValues, weights
		goal_mins = objective.global_min_values_per_goal
		goal_maxs = objective.global_max_values_per_goal

		ratios = subQualityValues.map_with_index do |v, i| 
			ratio i, v, goal_mins[i], goal_maxs[i]
		end

		# We cannot reuse the superclass in calculating the weighted sum since
		# we have already taken the signs into account in the ratio method.
		sum = 0.0
		ratios.each_with_index do |r, i|
			sum += (qv * weights[i])
		end

		sum / weights.sum.to_f
	end
end

# A Comparator ranks a set of candidates based on their sub-qualities.
# This default comparator just uses the quality value to sort the candidates, with
# lower values indicating a better quality.
class Objective::Comparator
	attr_accessor :objective

	# Return an array with the candidates ranked from best to worst.
	# Candidates that cannot be distinghuished from each other are randomly ranked.
	def rank_candidates candidates, weights
		candidates.sort_by {|c| objective.quality_of(c, weights).value}
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

	attr_reader :value, :sub_qualities, :objective, :version, :candidate

	def initialize(qv, subQvs, candidate, objective)
		@value, @sub_qualities, @objective = qv, subQvs, objective
		@candidate = candidate
		@version = objective.current_version
	end

	def <=>(other)
		# This ensures they are ranked according to latest version of objective.
		ranked = objective.rank_candidates [self.candidate, other.candidate]
		if ranked.last == self.candidate
			return 1
		else
			return -1
		end
	end

	# Return the sub quality value with a given index. Can make sure maximization
	# goals are mapped as minimization goals if ensureMinimization is true.
	def sub_quality(index, ensureMinimization = false)
		return @sub_qualities[index] if !ensureMinimization || @objective.is_min_goal?(index)
		# Now we now this is a max goal that should be returned as a min goal => invert it.
		-(@sub_qualities[index])
	end

	def to_s
		subqs = sub_qualities.map {|f| f.to_significant_digits(4)}
		"%.3g (SubQs = #{subqs.inspect}, ver. #{version})" % value
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

end