require 'feldtruby/optimize'
require 'feldtruby/optimize/objective'
require 'feldtruby/optimize/search_space'
require 'feldtruby/optimize/max_steps_termination_criterion'
require 'feldtruby/math/rand'
require 'feldtruby/array'
require 'feldtruby/logger'

module FeldtRuby::Optimize

# Find an vector of float values that optimizes a given
# objective.
class Optimizer
	include FeldtRuby::Logging

	attr_reader :options, :objective, :search_space, :best, :best_quality_value
	attr_reader :best_sub_quality_values, :num_optimization_steps, :termination_criterion

	def initialize(objective, searchSpace = FeldtRuby::Optimize::DefaultSearchSpace, options = {})
		@best = nil # To avoid warnings if not set
		@objective, @search_space = objective, searchSpace
		@options = FeldtRuby::Optimize.override_default_options_with(options)

		# Must setup logger before setting options since verbosity of logger is
		# an option!
		setup_logger_and_distribute_to_instance_variables(options)

		initialize_options(@options)
	end

	def initialize_options(options)
		self.logger.verbose = options[:verbose]
		@termination_criterion = options[:terminationCriterion]
	end

	# Optimize the objective in the given search space. 
	def optimize()
		logger.log "Optimization with optimizer #{self.class.inspect} started"
		@num_optimization_steps = 0
		# Set up a random best since other methods require it
		update_best([search_space.gen_candidate()])
		begin
			while !termination_criterion.terminate?(self)
				new_candidates = optimization_step()
				@num_optimization_steps += 1
				update_best(new_candidates)
			end
		rescue Exception => e
			logger.log_data :exception, {
				:exception_class => e.class.inspect, 
				:backtrace => e.backtrace.join("\n")
			}, "!!! - Optimization FAILED with exception: #{e.message} - !!!" + e.backtrace.join("\n")
		ensure
			logger.log "!!! - Optimization FINISHED after #{@num_optimization_steps} steps - !!!"
		end
		@objective.note_end_of_optimization(self)
		log_end_of_optimization
		@best # return the best
	end

	def log_end_of_optimization
		logger.log("End of optimization\n" + 
			"  Optimizer: #{self.class}\n" +
			"  Best found: #{@best}\n" +
			"  Quality of best: #{@objective.quality_of(@best)}\n" +
			"  Time used = #{Time.human_readable_timestr(logger.elapsed_time)}, " + 
			  "Steps performed = #{@num_optimization_steps}, " + 
			  "#{Time.human_readable_timestr(time_per_step, true)}/step")
	end

	def time_per_step
		logger.elapsed_time / @num_optimization_steps
	end

	# Run one optimization step. Default is to do nothing, i.e. this is just a superclass,
	# but subclasses need to implement this.
	def optimization_step()
	end

	# Update the best if a new best was found.
	def update_best(candidates)
		best_new, rest = objective.rank_candidates(candidates)
		if @best.nil? || @objective.is_better_than?(best_new, @best)
			qb = @best.nil? ? nil : @objective.quality_of(@best)
			logger.log_data :new_best, {
				"New best" => best_new,
				"New quality" => @objective.quality_of(best_new), 
				"Old best" => @best,
				"Old quality" => qb}, "New best solution found", true
			@best = best_new
			true
		else
			false
		end
	end
end

# Sample the indices of a population. This default super class just randomly
# samples without replacement.
class PopulationSampler
	def initialize(optimizer, options = FeldtRuby::Optimize::DefaultOptimizationOptions)
		@optimizer = optimizer
		@population_size = @optimizer.population_size
		initialize_all_indices()
	end

	def initialize_all_indices
		# We set up an array of the indices to all candidates of the population so we can later sample from it
		# This should always contain all indices even if they might be out of order. This is because we
		# only swap! elements in this array, never delete any.
		@all_indices = (0...@population_size).to_a
	end

	def sample_population_indices_without_replacement(numSamples)
		sample_indices_without_replacement numSamples, @all_indices
	end

	def sample_indices_without_replacement(numSamples, indices)
		sampled_indices = []
		size = indices.length
		numSamples.times do |i|
			index = i + rand_int(size - i)
			sampled_index, skip = indices.swap!(i, index)
			sampled_indices << sampled_index
		end
		sampled_indices
	end
end

# This implements a "trivial geography" similar to Spector and Kline (2006) 
# by first sampling an individual randomly and then selecting additional
# individuals for the same tournament within a certain deme of limited size
# for the sub-sequent individuals in the population. The version we implement
# here is from:
#  I. Harvey, "The Microbial Genetic Algorithm", in Advances in Artificial Life
#  Darwin Meets von Neumann, Springer, 2011.
class RadiusLimitedPopulationSampler < PopulationSampler
	def initialize(optimizer, options = FeldtRuby::Optimize::DefaultOptimizationOptions)
		super
		@radius = options[:samplerRadius]
	end

	def sample_population_indices_without_replacement(numSamples)
		i = rand(@population_size)
		indices = (i..(i+@radius)).to_a
		if (i+@radius) >= @population_size
			indices.map! {|i| i % @population_size}
		end
		sample_indices_without_replacement numSamples, indices
	end
end

class PopulationBasedOptimizer < Optimizer
	attr_reader :population

	def initialize_options(options)
		super
		@population_size = @options[:populationSize]
		initialize_population(@population_size)
		@sampler = options[:samplerClass].new(self, options)
	end

	# Create a population of a given size by randomly sampling candidates from the search space.
	def initialize_population(sizeOfPopulation)
		@population = Array.new(sizeOfPopulation).map {search_space.gen_candidate()}
	end

	# Re-initialize parts of the population.
	def re_initialize_population(percentageOfPopulation = 0.50)
		if percentageOfPopulation >= 1.00
			initialize_population(@population_size)
		else
			num_to_replace = (percentageOfPopulation * @population_size).to_i
			# We must use a PopulationSampler here instead of just calling sample_population_indices_without_replacement
			# since we do not know which sampler is installed.
			sampler = PopulationSampler.new(self, self.options)
			indices = sampler.sample_population_indices_without_replacement(num_to_replace)
			indices.each do |i|
				@population[i] = search_space.gen_candidate()
			end
		end
	end

	def population_size
		@population_size
	end

	# Sample indices from the population without replacement.
	def sample_population_indices_without_replacement(numSamples)
		@sampler.sample_population_indices_without_replacement(numSamples)
	end

	# Get candidates from population at given indices.
	def get_candidates_with_indices(indices)
		indices.map {|i| @population[i]}
	end

	# Get candidate from population at given index.
	def get_candidate(index)
		@population[index]
	end

	# Update population with candidate at given index.
	def update_candidate_in_population(index, candidate)
		@population[index] = candidate
	end
end

DefaultOptimizationOptions = {
	:terminationCriterionClass => FeldtRuby::Optimize::MaxStepsTerminationCriterion,
	:verbose => true,
	:populationSize => 200,
	:samplerClass => FeldtRuby::Optimize::RadiusLimitedPopulationSampler,
	:samplerRadius => 10 # Max distance between individuals selected in same tournament
}

def self.override_default_options_with(options)
	o = DefaultOptimizationOptions.clone.update(options)
	o[:terminationCriterion] = o[:terminationCriterionClass].new(o[:maxNumSteps])
	o
end

end