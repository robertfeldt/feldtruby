require 'feldtruby'
module FeldtRuby::Optimize; end

require 'feldtruby/optimize/differential_evolution'
module FeldtRuby::Optimize
	# Optimize the _numVariables_ between the _min_ and _max_ values given _costFunction_.
	# Default is to minimize.
	def self.optimize(numVariables, min, max, options = {}, 
		objectiveFuncClass = FeldtRuby::Optimize::ObjectiveMinimizeBlock, &costFunction)
		objective = objectiveFuncClass.new(&costFunction)
		search_space = FeldtRuby::Optimize::SearchSpace.new_from_min_max(numVariables, min, max)
		optimizer = FeldtRuby::Optimize::DifferentialEvolution.new(objective, search_space, options)
		optimizer.optimize()
		optimizer.best.to_a
	end

	def self.minimize(numVariables, min, max, options = {}, &costFunction)
		optimize(numVariables, min, max, options, &costFunction)
	end

	def self.maximize(numVariables, min, max, options = {}, &costFunction)
		optimize(numVariables, min, max, options, 
			FeldtRuby::Optimize::ObjectiveMaximizeBlock, &costFunction)
	end
end
