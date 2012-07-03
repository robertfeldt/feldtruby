require 'feldtruby'
module FeldtRuby::Optimize; end

require 'feldtruby/optimize/differential_evolution'
module FeldtRuby::Optimize
	# Optimize the _numVariables_ between the _min_ and _max_ values given _costFunction_.
	# Default is to minimize.
	def self.optimize(min, max, options = {}, 
		objectiveFuncClass = FeldtRuby::Optimize::ObjectiveMinimizeBlock, &costFunction)
		objective = objectiveFuncClass.new(&costFunction)
		num_vars = costFunction.arity
		search_space = FeldtRuby::Optimize::SearchSpace.new_from_min_max(num_vars, min, max)
		optimizer = FeldtRuby::Optimize::DifferentialEvolution.new(objective, search_space, options)
		optimizer.optimize()
		optimizer.best.to_a
	end

	def self.minimize(min, max, options = {}, &costFunction)
		optimize(min, max, options, &costFunction)
	end

	def self.maximize(min, max, options = {}, &costFunction)
		optimize(min, max, options, FeldtRuby::Optimize::ObjectiveMaximizeBlock, &costFunction)
	end
end
