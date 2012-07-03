require 'feldtruby/optimize/optimizer'
require 'feldtruby/math/rand'

# Common to many Evolutionary Computation optimizers
class FeldtRuby::Optimize::EvolutionaryOptimizer < FeldtRuby::Optimize::PopulationBasedOptimizer
end

# Differential Evolution for continuous, real-valued optimization.
class FeldtRuby::Optimize::DifferentialEvolution < FeldtRuby::Optimize::EvolutionaryOptimizer
	def optimization_step()
		# One step of DE is to sample 4 individuals
		pi0, pi1, pi2, pi3 = sample_population_indices_without_replacement(4)
		# This is just a random searcher for now...
		[search_space.gen_candidate()]
	end
end
