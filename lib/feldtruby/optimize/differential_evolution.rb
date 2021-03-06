require 'feldtruby/optimize/optimizer'
require 'feldtruby/math/rand'
require 'feldtruby/vector'
require 'feldtruby/logger'

module FeldtRuby::Optimize

# Common to many Evolutionary Computation optimizers
class EvolutionaryOptimizer < FeldtRuby::Optimize::PopulationBasedOptimizer; end

# Base class for Differential Evolution (DE) for continuous, real-valued optimization.
# Since there are many different DE variants this is the base class
# from which we can then include different strategy parts and create complete DE classes.
#
# A DE strategy generates a new trial vector as a candidate to replace a parent vector.
# It is composed of four parts:
#  - a mutation strategy that samples a set of parents to create a donor vector
#  - a crossover strategy which takes a donor and parent vector and creates a trial vector
#  - a bounding strategy which ensures the trial vector is within the search space
#  - an update strategy which can be used to self-adapt parameters based on feedback on improvements
#
# A strategy gets feedback on whether the latest trial vector was an improvement. It
# can use this feedback to adapt its operation over time.
#
# We implement strategies as Ruby Module's that we can include in different DE optimizer classes
# that inherits form the base one above. For maximum flexibility, each of the four parts of
# a DE strategy are implemented in separate Module's so we can mix and match them.
class DEOptimizerBase < EvolutionaryOptimizer
	DefaultOptions = {
		:DE_F_ScaleFactor 			=> 0.7,
		:DE_CR_CrossoverRate 		=> 0.5,
		:DE_NumParentsToSample	=> 4,
	}

	def initialize_options(options)
		super
		@options = DefaultOptions.clone.update(options)
		@f = @scale_factor = @options[:DE_F_ScaleFactor]
		@cr = @crossover_rate = @options[:DE_CR_CrossoverRate]
		@num_parents_to_sample = @options[:DE_NumParentsToSample]
	end

	# Create a population of a given size by randomly sampling candidates from the search space
	# and converting them to Vector's so we can more easily calculate on them later.
	def initialize_population(sizeOfPopulation)
		@population = Array.new(sizeOfPopulation).map {Vector.elements(search_space.gen_candidate())}
	end

	# Create a candidate from an array. By default we represent candidates with Ruby
	# vectors since they allow vector-based artihmetic.
	def candidate_from_array(ary)
		Vector.elements(ary)
	end

	# One step of the optimization is to (try to) update one vector. Thus, this is more of
	# a steady-state than a generational EC. DE is typically a generational EC but it is hard
	# to see any reason why. The default DE here is the classic DE/rand/1/*
	def optimization_step()
		trial, target, target_index = generate_trial_candidate_and_target()

		best, worst = objective.rank_candidates([target, trial])

		# Supplant the target vector with the trial vector if trial vector is better.
		if best != target
			logger.log_data :better_candidate_found, {
				"Trial" => trial, 
				"Trial Quality" => @objective.quality_of(trial),
				"Target" => target, 
				"Target Quality" => @objective.quality_of(target)
				}, "DE (step #{@num_optimization_steps}): Trial vector was better than target vector"
			update_candidate_in_population(target_index, trial)
			feedback_on_trial_vs_target(trial, target, true)
			[best]
		else
			feedback_on_trial_vs_target(trial, target, false)
			[]
		end
	end

	#####################################
	# Strategy-related methods. Can be overridden by strategies later. Below are the defaults.
  #####################################

	# Number of parents to sample. Default is that this is constant but can be overriden by
	# a mutation strategy.
	def num_parents_to_sample; options[:DE_NumParentsToSample]; end

	# Scale factor F.
	# Default is to use the one set in the optimizer, regardless of target vector.
	def scale_factor(targetVectorIndex); @f; end

	# Crossover rate. Default is to use the one set in the optimizer, regardless of position 
	# of the crossover position.
	def crossover_rate(position); @cr; end

	# Sample parents from the population and return their indices.
	def sample_parents()
		sample_population_indices_without_replacement(num_parents_to_sample)
	end

	# Main entry point for a DEStrategy. Generates a new trial vector and the parent
	# it targets.
	def generate_trial_candidate_and_target()
		# Sample parents. The first parent returned is used as target parent to cross-over with. 
		# Rest of the sampled parents is/can be used in mutation.
		target_parent_index, *parent_indices = sample_parents()
		target = get_candidate(target_parent_index)

		# The three main steps. We get feedback from optimizer at a later stage.
		donor = mutate(target_parent_index, parent_indices) # Should be implemented by a MutationStrategy
		trial = crossover_donor_and_target(target, donor, 
							target_parent_index) 											# Should be implemented by a CrossoverStrategy
		trial = bound_trial_candidate(trial)								# Should be implemented by a BoundingStrategy

		return trial, target, target_parent_index
	end
end

module DE_BoundingStrategy_RandomWithinSearchSpace
	# Default bounding strategy is to bound by the search space.
	def bound_trial_candidate(candidate)
		search_space.bound(candidate)
	end
end

module DE_UpdateStrategy_NoFeedbackUpdates
	# We can use feedback from optimizer to improve. Default is to not change anything.
	def feedback_on_trial_vs_target(trial, target, trialBetter); end
end

# This is the classic binomial DE/*/*/bin crossover.
module DE_CrossoverStrategy_Binomial
	def crossover_donor_and_target(targetVector, donorVector, targetVectorIndex)
		num_variables = donorVector.size
		jrand = rand_int(num_variables)
		trial_vector = targetVector.clone.to_a		# We use the targetVector values as a starting point
		trial_vector[jrand] = donorVector[jrand]	# Always copy one random var to ensure some difference.
		num_variables.times do |j|
			trial_vector[j] = donorVector[j] if rand() <= crossover_rate(j) # Copy with crossover_rate probability
		end
		candidate_from_array(trial_vector)
	end
end

# The most-used DE/rand/1/* mutation strategy.
module DE_MutationStrategy_Rand_1
	# We need three parents for donor vector. And then the target, so 1+3 in total.
	def num_parents_to_sample; 4; end

	def mutate(targetIndex, donorParentsIndices)
		p1, p2, p3 = get_candidates_with_indices(donorParentsIndices)
		p3 + (scale_factor(targetIndex) * (p1 - p2))
	end
end

# DE/rand/1/bin uses 
#   Bounding  = random bounding within the search space
#   Update 	  = no updates based on feedback
#   Crossover = Classic binomial
#   Mutation  = Rand-1
class DEOptimizer_Rand_1_Bin < DEOptimizerBase
	include DE_BoundingStrategy_RandomWithinSearchSpace
	include DE_UpdateStrategy_NoFeedbackUpdates
	include DE_CrossoverStrategy_Binomial
	include DE_MutationStrategy_Rand_1
end

# The DE/best/1/* mutation strategy.
module DE_MutationStrategy_Best_1
	# We need two parents for donor vector. And then the target, so 1+2 in total.
	def num_parents_to_sample; 3; end

	def mutate(targetIndex, donorParentsIndices)
		p1, p2 = get_candidates_with_indices(donorParentsIndices)
		candidate_from_array(best) + (scale_factor(targetIndex) * (p1 - p2))
	end
end

# DE/best/1/bin uses
#   Bounding  = random bounding within the search space
#   Update 	  = no updates based on feedback
#   Crossover = Classic binomial
#   Mutation  = Best-1
class DEOptimizer_Best_1_Bin < DEOptimizerBase
	include DE_BoundingStrategy_RandomWithinSearchSpace
	include DE_UpdateStrategy_NoFeedbackUpdates
	include DE_CrossoverStrategy_Binomial
	include DE_MutationStrategy_Best_1
end

# The DE/best/1/* mutation strategy.
module DE_MutationStrategy_Best_2
	# We need four parents for two donor vectors. And then the target, so 1+4 in total.
	def num_parents_to_sample; 5; end

	def mutate(targetIndex, donorParentsIndices)
		p1, p2, p3, p4 = get_candidates_with_indices(donorParentsIndices)
		f = scale_factor(targetIndex)
		candidate_from_array(best) + (f * (p1 - p2)) + (f * (p3 - p4))
	end
end

class DEOptimizer_Best_2_Bin < DEOptimizer_Best_1_Bin
	include DE_MutationStrategy_Best_2
end

# DE/rand/1/bin is the default DE optimizer since it does not converge too
# quickly but is generally good. For many problems the DEOptimizer_Best_1_Bin
# gives better results faster though.
DEOptimizer = DEOptimizer_Rand_1_Bin
#DEOptimizer = DEOptimizer_Best_2_Bin

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