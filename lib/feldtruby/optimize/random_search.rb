require 'feldtruby/optimize/optimizer'

# Random search that optimizes a given objective function.
class FeldtRuby::Optimize::RandomSearcher < FeldtRuby::Optimize::Optimizer
	def optimization_step()
		# For random search we just generate a new random candidate in each step.
		[search_space.gen_candidate()]
	end
end
