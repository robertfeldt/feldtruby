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
	def quality_value(candidate)
		num_aspects == 1 ? qv_single(candidate) : qv_swgr(candidate)
	end

	# Return the quality value assuming this is a single objective.
	def qv_single(candidate)
		self.send(aspect_methods.first, candidate)
	end

	private

	def aspect_methods
		@aspect_methods ||= self.methods.select {|m| is_aspect_method?(m)}
	end

	def is_aspect_method?(methodNameAsSymbolOrString)
		methodNameAsSymbolOrString.to_s =~ /^objective_(min)|(max)_([\w_]+)$/
	end
end