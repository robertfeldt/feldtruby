require 'feldtruby/optimize'
require 'feldtruby/optimize/objective'
require 'feldtruby/optimize/search_space'
require 'feldtruby/optimize/stdout_logging_statistics_collector'
require 'feldtruby/optimize/max_steps_termination_criterion'
require 'feldtruby/math/rand'

module FeldtRuby::Optimize 
	DefaultOptimizationOptions = {
		:statisticsCollector => FeldtRuby::Optimize::StdOutLoggingStatisticsCollector,
		:maxNumSteps => 1000,
		:terminationCriterionClass => FeldtRuby::Optimize::MaxStepsTerminationCriterion,
		:verbose => true,
		:populationSize => 100,
	}

	def self.override_default_options_with(options)
		o = DefaultOptimizationOptions.clone.update(options)
		o[:terminationCriterion] = o[:terminationCriterionClass].new(o[:maxNumSteps])
		o
	end
end

# Find an vector of float values that optimizes a given
# objective.
class FeldtRuby::Optimize::Optimizer
	attr_reader :objective, :search_space, :best, :best_quality_value, :num_optimization_steps, :termination_criterion

	def initialize(objective, searchSpace = FeldtRuby::Optimize::DefaultSearchSpace, options = {})
		@objective, @search_space = objective, searchSpace
		@options = FeldtRuby::Optimize.override_default_options_with(options)
		@stats = @options[:statisticsCollector].new(self, @options[:verbose])
		@termination_criterion = @options[:terminationCriterion]
	end

	# Optimize the objective in the given search space. 
	def optimize()
		@num_optimization_steps = 0
		# Set up a random best since other methods require it
		update_best([search_space.gen_candidate()])
		begin
			@stats.note_optimization_starts()
			while !termination_criterion.terminate?(self)
				new_candidates = optimization_step()
				@num_optimization_steps += 1
				@stats.note_another_optimization_step(@num_optimization_steps)
				update_best(new_candidates)
			end
		rescue Exception => e
			@stats.note_termination("!!! - Optimization FAILED with exception: #{e.message} - !!!" + e.backtrace.join("\n"))
		ensure	
			@stats.note_termination("!!! - Optimization FINISHED after #{@num_optimization_steps} steps - !!!")
		end
		@best # return the best
	end

	# Run one optimization step. Default is to do nothing, i.e. this is just a superclass,
	# but subclasses need to implement this.
	def optimization_step()
	end

	# Rank all candidates, then update the best one if a new best found.
	def update_best(candidates)
		if @best
			ranked = objective.rank_candidates(candidates + [@best])
		else
			ranked = objective.rank_candidates(candidates)
		end
		new_best, new_quality_value, new_sub_qvalues = ranked.first
		# Since some objectives are not deterministic the best
		if new_best != @best
			if @best
				old_best, new_qv_old_best, sub_qv_old_best = ranked.select {|a| a.first == @best}.first
			end
			@stats.note_new_best(new_best, new_quality_value, new_sub_qvalues, 
				@best, new_qv_old_best, sub_qv_old_best)
			@best = new_best
			@best_quality_value = new_quality_value
			@best_sub_qvalues = new_sub_qvalues
			true
		else
			false
		end
	end
end

class FeldtRuby::Optimize::PopulationBasedOptimizer < FeldtRuby::Optimize::Optimizer
	attr_reader :population

	def initialize(objective, searchSpace = FeldtRuby::Optimize::DefaultSearchSpace, options = {})
		super
		initialize_population(@options[:populationSize])
		initialize_all_indices()
	end

	# Create a population of a given size by randomly sampling candidates from the search space.
	def initialize_population(sizeOfPopulation)
		@population = Array.new(sizeOfPopulation).map {search_space.gen_candidate()}
	end

	def population_size
		@population.length
	end

	def initialize_all_indices
		# We set up an array of the indices to all candidates of the population so we can later sample from it
		# This should always contain all indices even if they might be out of order. This is because we
		# only swap! elements in this array, never delete any.
		@all_indices = (0...population_size).to_a
	end

	# Sample indices from the population without replacement.
	def sample_population_indices_without_replacement(numSamples)
		sampled_indices = []
		numSamples.times do |i|
			index = i + rand_int(population_size - i)
			sampled_index, skip = @all_indices.swap!(i, index)
			sampled_indices << sampled_index
		end
		sampled_indices
	end

	# Get candidates from population at given indices.
	def candidates_with_indices(indices)
		indices.map {|i| @population[i]}
	end
end

