require 'feldtruby/optimize/optimizer'
require 'feldtruby/math/rand'
require 'feldtruby/vector'

# Common to many Evolutionary Computation optimizers
class FeldtRuby::Optimize::EvolutionaryOptimizer < FeldtRuby::Optimize::PopulationBasedOptimizer
end

# Differential Evolution for continuous, real-valued optimization.
class FeldtRuby::Optimize::DifferentialEvolution < FeldtRuby::Optimize::EvolutionaryOptimizer
	def initialize_options(options)
		super
		@f = @scale_factor = options[:DE_F_ScaleFactor] || 0.8
		@cr = @crossover_rate = options[:DE_CR_CrossoverRate] || 0.4
		@num_parents_to_sample = options[:DE_NumParentsToSample] || 4
	end

	# Create a population of a given size by randomly sampling candidates from the search space
	# and converting them to Vector's so we can more easily calculate on them later.
	def initialize_population(sizeOfPopulation)
		@population = Array.new(sizeOfPopulation).map {Vector.elements(search_space.gen_candidate())}
	end

	# One step of the optimization is to (try to) update one vector. Thus, this is more of
	# a steady-state than a generational EC. DE is typically a generational EC but it is hard
	# to see any reason why. The default DE here is the classic DE/rand/1/*
	def optimization_step()
		target_parent_index, *parent_indices = sample_parents()
		target_parent_vector = @population[target_parent_index]

		donor_vector = mutate_parents(parent_indices)

		trial_vector = crossover(target_parent_vector, donor_vector)

		# We must bound the trial vector inside the search space
		trial_vector = search_space.bound(trial_vector)

		# We get [candidate, qualityValue, subQualityValues for each vector
		bestV, worstV = objective.rank_candidates([target_parent_vector, trial_vector])

		# Supplant the target vector with the trial vector if better
		if bestV.first != target_parent_vector
			@stats.note_new_better("Trial vector was better", *bestV)
			@population[target_parent_index] = bestV.first
		end

		[bestV.first]
	end

	def sample_parents()
		sample_population_indices_without_replacement(@num_parents_to_sample)
	end

	def get_parents_with_indices(indices)
		indices.map {|i| @population[i]}
	end

	# Mutate a set of parent vectors into a new trial vector. Default mutation
	# is the classic DE/rand/1/*.
	def mutate_parents(parentIndices)
		de_rand_1 *get_parents_with_indices(parentIndices)
	end

	# Classic DE/rand/1 donor vector generation
	def de_rand_1(p1, p2, p3)
		p1 + @f * (p2 - p3)
	end

	# This is the classic binomial DE/*/*/bin crossover.
	def crossover(targetVector, donorVector)
		d = donorVector.size
		jrand = rand_int(d)
		# We use the targetVector values as a starting point
		trial_vector = targetVector.to_a
		d.times do |j|
			trial_vector[j] = donorVector[j] if (rand() <= @cr || j == jrand)
		end
		Vector.elements(trial_vector)
	end
end
