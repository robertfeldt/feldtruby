# Objective Functions that measure quality of solutions in optimization.

require 'feldtruby/optimize'

# An Objective captures one or more objectives into a single object
# and supports a large number of ways to utilize basic objective
# functions in a single framework. You subclass and add instance
# methods named as 
#   objective_min_qualityAspectName (for an objective/aspect to be minimized), or 
#   objective_max_qualityAspectName (for an objective/aspect to be minimized).
# There can be multiple aspects (sub-objectives) for a single objective.
class FeldtRuby::Optimize::Objective
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
		num_aspects == 1 ? qv_single(candidate) : qv_mwgr(candidate, weights)
	end

	def rank_candidates(candidates, weights = nil)
		mwgr_rank_candidates(candidates, weights)
	end

	# Rand candidates from best to worst. NOTE! We do the steps of MWGR separately since we must
	# update the global mins and maxs before calculating the SWG ratios.
	def mwgr_rank_candidates(candidates, weights = nil)
		sub_qvss = candidates.map {|c| sub_objective_values(c)}
		sub_qvss.each {|sub_qvs| update_global_mins_and_maxs(sub_qvs)}
		sub_qvss.each_with_index.map do |sub_qvs, i| 
			[candidates[i], mwgr_ratios(sub_qvs).weighted_mean(weights), sub_qvs]
		end.sort_by {|a| -a[1]} # sort by the ratio values
	end

	# Return the quality value assuming this is a single objective.
	def qv_single(candidate)
		self.send(aspect_methods.first, 
			map_candidate_vector_to_candidate_to_be_evaluated(candidate))
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

	def update_global_mins_and_maxs(aspectValues)
		aspectValues.each_with_index {|v, i| update_global_min_and_max(i, v)}
	end

	def update_global_min_and_max(aspectIndex, value)
		global_min_values_per_aspect[aspectIndex] = [global_min_values_per_aspect[aspectIndex], value].min
		global_max_values_per_aspect[aspectIndex] = [global_max_values_per_aspect[aspectIndex], value].max
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

# Short hand for when the objective function is given as a block that should be minimized.
class FeldtRuby::Optimize::ObjectiveMinimizeBlock < FeldtRuby::Optimize::Objective
	def initialize(&objFunc)
		@objective_function = objFunc
	end

	def objective_min_cost_function(candidate)
		@objective_function.call(*candidate.to_a)
	end
end

# Short hand for when the objective function is given as a block that should be minimized.
class FeldtRuby::Optimize::ObjectiveMaximizeBlock < FeldtRuby::Optimize::Objective
	def initialize(&objFunc)
		@objective_function = objFunc
	end

	def objective_max_cost_function(candidate)
		@objective_function.call(*candidate.to_a)
	end
end