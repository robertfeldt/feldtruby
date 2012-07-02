# Objective Functions that measure quality of solutions in optimization.

require 'feldtruby'

module FeldtRuby::Optimize; end

# An Objective captures one or more objectives into a single object
# and supports a large number of ways to utilize basic objective
# functions in a single framework. You subclass and add instance
# methods named as 
#   objective_min_qualityAspectName (for an objective/aspect to be minimized), or 
#   objective_max_qualityAspectName (for an objective/aspect to be minimized).
# There can be multiple aspects (sub-objectives) for a single objective.
class FeldtRuby::Optimize::Objective
	def initialize
	end

	# Return the number of aspects/sub-objectives of this objective.
	def num_aspects
		@num_aspects ||= aspect_methods.length
	end

	# Return a single quality value for the whole objective for a given candidate. 
	# By default this uses Bentley and Wakefield's sum-of-weighted-global-ratios (SWGR) 
	# if there are multiple aspects/sub-objectives. If this is a single objective we 
	# just return the value of the objective_X method.
	def quality_value(candidate, weights = nil)
		num_aspects == 1 ? qv_single(candidate) : qv_swgr(candidate, weights)
	end

	# Return the quality value assuming this is a single objective.
	def qv_single(candidate)
		self.send(aspect_methods.first, candidate)
	end

	# Sum-of-weigthed-global-ratios (SWGR) quality value
	def qv_swgr(candidate, weights = nil)
		sub_qvs = sub_objective_values(candidate)
		update_global_mins_and_maxs(sub_qvs)
		swgr_ratios(sub_qvs).weighted_sum(weights)
	end

	# Calculate the SWGR ratios
	def swgr_ratios(subObjectiveValues)
		subObjectiveValues.each_with_index.map {|v,i| ratio_for_aspect(i, v)}
	end

	def ratio_for_aspect(aspectIndex, value)
		min, max = global_min_values_per_aspect[aspectIndex], global_max_values_per_aspect[aspectIndex]
		if is_min_aspect?(aspectIndex)
			numerator = max - value
		else
			numerator = value - min
		end
		numerator / (max - min)
	end

	def sub_objective_values(candidate)
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