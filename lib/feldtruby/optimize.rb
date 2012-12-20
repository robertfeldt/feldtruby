require 'feldtruby'

module FeldtRuby::Optimize; end

require 'feldtruby/optimize/differential_evolution'
module FeldtRuby::Optimize
	# Optimize the _numVariables_ between the _min_ and _max_ values given _costFunction_.
	# Default is to minimize.
	def self.optimize(min, max, options = {:verbose => true}, 
		objectiveFuncClass = FeldtRuby::Optimize::ObjectiveMinimizeBlock, &costFunction)
		objective = objectiveFuncClass.new(&costFunction)
		num_vars = costFunction.arity
		search_space = SearchSpace.new_from_min_max(num_vars, min, max)
		optimizer = DEOptimizer.new(objective, search_space, options)
		optimizer.optimize()
		optimizer.best.to_a
	end

	# Short hand wrapper for function minimization.
	def self.minimize(min, max, options = {}, &costFunction)
		optimize(min, max, options, &costFunction)
	end

	# Short hand wrapper for function maximization.
	def self.maximize(min, max, options = {}, &costFunction)
		optimize(min, max, options, FeldtRuby::Optimize::ObjectiveMaximizeBlock, &costFunction)
	end
end
