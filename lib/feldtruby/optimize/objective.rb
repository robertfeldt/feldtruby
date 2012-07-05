# Objective Functions that measure quality of solutions in optimization.

require 'feldtruby/optimize'

# An Objective captures one or more objectives into a single object
# and supports a large number of ways to utilize basic objective
# functions in a single framework. You subclass and add instance
# methods named as 
#   objective_min_qualityAspectName (for an objective/aspect to be minimized), or 
#   objective_max_qualityAspectName (for an objective/aspect to be minimized).
# There can be multiple aspects (sub-objectives) for a single objective.
# This base class uses mean-weighted-global-ratios (MWGR) as the default mechanism
# for handling multi-objectives i.e. with more than one sub-objective. 
# An objective has version numbers to indicate the number of times the scale 
# for the calculation of the ratios has been changed.
class FeldtRuby::Optimize::Objective
	attr_accessor :current_version, :logger

	def initialize
		@current_version = 0
		@pareto_front = Array.new(num_aspects)
	end

	def reset_quality_scale(candidate, aspectIndex, typeOfReset)
		if (typeOfReset == :min && is_min_aspect?(aspectIndex)) || 
		   (typeOfReset == :max && !is_min_aspect?(aspectIndex))
			@pareto_front[aspectIndex] = candidate
		end

		# Reset the best object since we have a new scale
		@best_candidate = nil
		@best_qv = nil

		inc_version_number
	end

	def update_best_candidate(candidate)
		@best_candidate = candidate
		@best_qv = candidate._quality_value
	end

	def inc_version_number
		@current_version += 1
	end

	# Return the number of aspects/sub-objectives of this objective.
	def num_aspects
		@num_aspects ||= aspect_methods.length
	end

	# Return a single quality value for the whole objective for a given candidate. 
	# By default this uses a variant of Bentley and Wakefield's sum-of-weighted-global-ratios (SWGR)
	# called mean-of-weighted-global-ratios (MWGR) which always returns a fitness value
	# in the range (0.0, 1.0) with 1.0 signaling the best fitness seen so far. The scale is adaptive
	# though so that the best candidate so far always has a fitness value of 1.0.
	def quality_value(candidate, weights = nil)
		return candidate._quality_value_without_check if quality_value_is_up_to_date?(candidate)
		num_aspects == 1 ? qv_single(candidate) : qv_mwgr(candidate, weights)
	end

	def quality_value_is_up_to_date?(candidate)
		candidate._objective == self && candidate._objective_version == current_version
	end

	def update_quality_value_in_object(object, qv)
		object._objective = self
		object._objective_version = current_version
		object._quality_value_without_check = qv
	end

	def ensure_updated_quality_value(candidate)
		return if quality_value_is_up_to_date?(candidate)
		quality_value(candidate)
	end

	def rank_candidates(candidates, weights = nil)
		mwgr_rank_candidates(candidates, weights)
	end

	# Rand candidates from best to worst. NOTE! We do the steps of MWGR separately since we must
	# update the global mins and maxs before calculating the SWG ratios.
	def mwgr_rank_candidates(candidates, weights = nil)
		sub_qvss = candidates.map {|c| sub_objective_values(c)}
		sub_qvss.zip(candidates).each {|sub_qvs, c| update_global_mins_and_maxs(sub_qvs, c)}
		sub_qvss.each_with_index.map do |sub_qvs, i|
			qv = mwgr_ratios(sub_qvs).weighted_mean(weights)
			update_quality_value_in_object(candidates[i], qv)
			[candidates[i], qv, sub_qvs]
		end.sort_by {|a| -a[1]} # sort by the ratio values in descending order
	end

	def note_end_of_optimization(optimizer)
		log("Objective reporting the Pareto front", info_pareto_front())
	end

	def info_pareto_front
		@pareto_front.each_with_index.map do |c, i|
			"Pareto front candidate for objective #{aspect_methods[i]}: #{map_candidate_vector_to_candidate_to_be_evaluated(c).inspect}"
		end.join("\n")
	end

	# Return the quality value assuming this is a single objective.
	def qv_single(candidate)
		qv = self.send(aspect_methods.first, 
			map_candidate_vector_to_candidate_to_be_evaluated(candidate))
		update_quality_value_in_object(candidate, qv)
		qv
	end

	# Mean-of-weigthed-global-ratios (MWGR) quality value
	def qv_mwgr(candidate, weights = nil)
		mwgr_rank_candidates([candidate], weights).first[1]
	end

	# Calculate the SWGR ratios
	def mwgr_ratios(subObjectiveValues)
		subObjectiveValues.each_with_index.map {|v,i| ratio_for_aspect(i, v)}
	end

	def protected_division(num, denom)
		return 0.0 if denom == 0
		num / denom
	end

	def ratio_for_aspect(aspectIndex, value)
		min, max = global_min_values_per_aspect[aspectIndex], global_max_values_per_aspect[aspectIndex]
		if is_min_aspect?(aspectIndex)
			numerator = max - value
		else
			numerator = value - min
		end
		protected_division(numerator.to_f, max - min)
	end

	# The vectors can be mapped to a more complex candidate object before we call
	# the sub objectives to calc their quality values. Default is no mapping but subclasses
	# can override this.
	def map_candidate_vector_to_candidate_to_be_evaluated(vector)
		vector
	end

	def sub_objective_values(candidateVector)
		candidate = map_candidate_vector_to_candidate_to_be_evaluated(candidateVector)
		aspect_methods.map {|omethod| self.send(omethod, candidate)}
	end

	def update_global_mins_and_maxs(aspectValues, candidate = nil)
		aspectValues.each_with_index {|v, i| update_global_min_and_max(i, v, candidate)}
	end

	def update_global_min_and_max(aspectIndex, value, candidate)
		min = global_min_values_per_aspect[aspectIndex]
		if value < min
			reset_quality_scale(candidate, aspectIndex, :min)
			global_min_values_per_aspect[aspectIndex] = value
			log_new_min_max(aspectIndex, value, min, "min")
		end
		max = global_max_values_per_aspect[aspectIndex]
		if value > max
			reset_quality_scale(candidate, aspectIndex, :max)
			global_max_values_per_aspect[aspectIndex] = value
			log_new_min_max(aspectIndex, value, max, "max")
		end
	end

	def log_new_min_max(index, newValue, oldValue, description)
		log("New global #{description} for sub-objective #{aspect_methods[index]}",
			("a %.3f" % (100.0 * protected_division(newValue - oldValue, oldValue))) + "% difference",
			"new = #{newValue}, old = #{oldValue}",
			"scale is now [#{global_min_values_per_aspect[index]}, #{global_max_values_per_aspect[index]}]",
			"objective version = #{current_version}")
	end

	def log(msg, *values)
		@logger.anote(msg, *values) if @logger
	end

	# Global min values for each aspect. Needed for SWGR. Updated every time we see a new
	# quality value for an aspect.
	# All are minus infinity when we have not seen any values yet.
	def global_min_values_per_aspect
		@global_min_values_per_aspect ||= Array.new(num_aspects).map {Float::INFINITY}
	end

	# Global max values for each aspect. Needed for SWGR. Updated every time we see a new
	# quality value for an aspect.
	# All are minus infinity when we have not seen any values yet.
	def global_max_values_per_aspect
		@global_max_values_per_aspect ||= Array.new(num_aspects).map {-Float::INFINITY}
	end

	private

	def aspect_methods
		@aspect_methods ||= self.methods.select {|m| is_aspect_method?(m)}
	end

	def is_min_aspect?(aspectIndex)
		(@is_min_aspect ||= (aspect_methods.map {|m| is_min_aspect_method?(m)}))[aspectIndex]
	end

	def is_aspect_method?(methodNameAsSymbolOrString)
		methodNameAsSymbolOrString.to_s =~ /^objective_(min|max)_([\w_]+)$/
	end

	def is_min_aspect_method?(methodNameAsSymbolOrString)
		methodNameAsSymbolOrString.to_s =~ /^objective_min_([\w_]+)$/
	end
end

# We add strangely named accessor methods so we can attach the quality values to objects.
# We use strange names to minimize risk of method name conflicts.
class Object
	attr_accessor :_quality_value_without_check, :_objective, :_objective_version
	def _quality_value
		@_objective.ensure_updated_quality_value(self) if @_objective
		@_quality_value_without_check
	end
end

# Short hand for when the objective function is given as a block that should be minimized.
class FeldtRuby::Optimize::ObjectiveMinimizeBlock < FeldtRuby::Optimize::Objective
	def initialize(&objFunc)
		super()
		@objective_function = objFunc
	end

	def objective_min_cost_function(candidate)
		@objective_function.call(*candidate.to_a)
	end
end

# Short hand for when the objective function is given as a block that should be minimized.
class FeldtRuby::Optimize::ObjectiveMaximizeBlock < FeldtRuby::Optimize::Objective
	def initialize(&objFunc)
		super()
		@objective_function = objFunc
	end

	def objective_max_cost_function(candidate)
		@objective_function.call(*candidate.to_a)
	end
end