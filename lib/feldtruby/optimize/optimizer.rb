require 'feldtruby/optimize'
require 'feldtruby/optimize/objective'
require 'feldtruby/optimize/search_space'
require 'feldtruby/optimize/max_steps_termination_criterion'
require 'feldtruby/optimize/archive'
require 'feldtruby/math/rand'
require 'feldtruby/array'
require 'feldtruby/logger'

module FeldtRuby::Optimize

# Find an vector of float values that optimizes a given
# objective.
class Optimizer
	include FeldtRuby::Logging

	attr_reader :options, :objective, :search_space, :archive
	attr_reader :num_optimization_steps, :termination_criterion

	def initialize(objective, searchSpace = FeldtRuby::Optimize::DefaultSearchSpace, options = {})
		@objective, @search_space = objective, searchSpace
		@options = FeldtRuby::Optimize.override_default_options_with(options)

		init_archive

		# Must setup logger before setting options since verbosity of logger is
		# an option!
		setup_logger_and_distribute_to_instance_variables(options)

		initialize_options(@options)
	end

	def init_archive
		if @options[:archive]

			@archive = @options[:archive]

		else

			if @options[:archiveDiversityObjective]
				diversity_objective = @options[:archiveDiversityObjective]
			else
				diversity_objective = @options[:archiveDiversityObjectiveClass].new
			end
		
			@archive = @options[:archiveClass].new(@objective, diversity_objective)

		end
	end

	def best
		@archive.best
	end

	def initialize_options(options)
		self.logger.verbose = options[:verbose]
		@termination_criterion = options[:terminationCriterion]
	end

	# Setup for optimization unless we have already been setup...
	def setup_for_optimization
		return if has_been_setup?
		logger.log "Setting up for optimization with optimizer #{self.class.inspect}"
		@num_optimization_steps = 0
		# Set up a random best for now that we can later compare to.
		update_archive [search_space.gen_candidate()]
		@has_been_setup = true
	end

	# True iff we have already been setup.
	def has_been_setup?
		@has_been_setup
	end

	# Run the optimizer a given number of steps
	def optimize_num_steps(numberOfSteps = 1000)
		setup_for_optimization
		# We create a criterion specific to this round. It will stop after the given
		# number of steps.
		stop_at_steps = @num_optimization_steps + numberOfSteps
		criterion = FeldtRuby::Optimize::MaxStepsTerminationCriterion.new stop_at_steps
		logger.log "Optimization for #{numberOfSteps} steps with optimizer #{self.class.inspect} started"
		optimize_until_termination criterion
		archive.best # return the best
	end

	def optimize_until_termination(terminationCriterion = self.termination_criterion)
		begin
			while !terminationCriterion.terminate?(self)
				new_candidates = optimization_step()
				@num_optimization_steps += 1
				update_archive new_candidates
			end
		rescue Exception => e
			puts e.inspect
			logger.log_data :exception, {
				:exception_class => e.class.inspect, 
				:backtrace => e.backtrace.join("\n")
			}, "!!! - Optimization FAILED with exception: #{e.message} - !!!" + e.backtrace.join("\n")
		ensure
			logger.log "!!! - Optimization ended after #{@num_optimization_steps} steps - !!!"
		end
	end

	# Optimize the objective in the given search space. 
	def optimize()
		setup_for_optimization
		logger.log "Optimization with optimizer #{self.class.inspect} started"
		optimize_until_termination self.termination_criterion
		@objective.note_end_of_optimization(self)
		log_end_of_optimization
		archive.best # return the best
	end

	def log_end_of_optimization
		logger.log("End of optimization\n" + 
			"  Optimizer: #{self.class}\n" +
			"  Best found: #{@archive.best}\n" +
			"  Quality of best: #{@objective.quality_of(@archive.best)}\n" +
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

	# Update the archive with newly found candidates. Array of candidates may be empty if
	# no new candidates found.
	def update_archive(candidates)
		candidates.each {|c| @archive.add_if_interesting(c)}
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
	:populationSize => 100,
	:samplerClass => FeldtRuby::Optimize::RadiusLimitedPopulationSampler,
	:samplerRadius => 8, # Max distance between individuals selected in same tournament.
	:archive => nil, # If this is set it takes precedence over archiveClass.
	:archiveClass => FeldtRuby::Optimize::DiversityArchive,
	:archiveDiversityObjective => nil, # If this is set it takes precedence over the class in archiveDiversityObjectiveClass
	:archiveDiversityObjectiveClass => FeldtRuby::Optimize::EuclideanDistanceToBest,
}

def self.override_default_options_with(options)
	o = DefaultOptimizationOptions.clone.update(options)
	o[:terminationCriterion] = o[:terminationCriterionClass].new(o[:maxNumSteps])
	o
end

end