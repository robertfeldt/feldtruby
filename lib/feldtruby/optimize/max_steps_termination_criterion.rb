require 'feldtruby/optimize'

class FeldtRuby::Optimize::TerminationCriterion
	# Default termination criterion is to never terminate
	def terminate?(optimizer)
		false
	end

	# Inverse of terminate?, i.e. should we continue optimizing?
	def continue_optimization?
		!terminate?
	end
end

class FeldtRuby::Optimize::MaxStepsTerminationCriterion < FeldtRuby::Optimize::TerminationCriterion
	def initialize(maxSteps)
		@max_steps = maxSteps
	end
	def terminate?(optimizer)
		optimizer.num_optimization_steps >= @max_steps
	end
end