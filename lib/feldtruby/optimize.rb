require 'feldtruby'
module FeldtRuby::Optimize; end

require 'feldtruby/optimize/differential_evolution'
module FeldtRuby::Optimize
	def self.optimize(numVariables, min, max, options = {}, &costFunction)
		objective = FeldtRuby::Optimize::ObjectiveInBlock.new(&costFunction)
		search_space = FeldtRuby::Optimize::SearchSpace.new_from_min_max(numVariables, min, max)
		optimizer = FeldtRuby::Optimize::DifferentialEvolution.new(objective, search_space, options)
		optimizer.optimize()
		optimizer.best.to_a
	end
end
