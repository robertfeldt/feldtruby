require 'feldtruby/optimize'
require 'feldtruby/optimize/objective'
require 'feldtruby/optimize/search_space'
require 'feldtruby/optimize/max_steps_termination_criterion'
require 'feldtruby/math/rand'
require 'feldtruby/array'
require 'feldtruby/logger'

module FeldtRuby

module Optimize 
	DefaultOptimizationOptions = {
		:terminationCriterionClass => FeldtRuby::Optimize::MaxStepsTerminationCriterion,
		:verbose => false,
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
class Optimize::Optimizer
	include FeldtRuby::Logging

	attr_reader :objective, :search_space, :best, :best_quality_value, :best_sub_quality_values, :num_optimization_steps, :termination_criterion

	def initialize(objective, searchSpace = FeldtRuby::Optimize::DefaultSearchSpace, options = {})
		@best = nil # To avoid warnings if not set
		@objective, @search_space = objective, searchSpace
		@options = FeldtRuby::Optimize.override_default_options_with(options)

		# Must setup logger before setting options since verbosity of logger is
		# an option!
		setup_logger_and_distribute_to_instance_variables()

		initialize_options(@options)
	end

	def initialize_options(options)
		self.logger.verbose = options[:verbose]
		@termination_criterion = options[:terminationCriterion]
	end

	# Optimize the objective in the given search space. 
	def optimize()
		@num_optimization_steps = 0
		# Set up a random best since other methods require it
		update_best([search_space.gen_candidate()])
		begin
			log "Optimization with optimizer #{self.class.inspect} started"
			while !termination_criterion.terminate?(self)
				new_candidates = optimization_step()
				@num_optimization_steps += 1
				#log_value :NumOptimizationSteps, @num_optimization_steps # This takes a loooong time if using EventLogger. Need to simplify!
				update_best(new_candidates)
			end
		rescue Exception => e
			log( "!!! - Optimization FAILED with exception: #{e.message} - !!!" + e.backtrace.join("\n"), 
				:exception, {:exception_class => e.class.inspect, :backtrace => e.backtrace.join("\n")} )
		ensure
			log_value :NumOptimizationSteps, @num_optimization_steps,
				"!!! - Optimization FINISHED after #{@num_optimization_steps} steps - !!!"
		end
		@objective.note_end_of_optimization(self)
		log_end_of_optimization
		@best # return the best
	end

	def log_end_of_optimization
		best_msg = info_about_candidate(self.best, self.best_quality_value, 
			self.best_sub_quality_values, "best")
		log("End of optimization" + "Optimizer: #{self.class}\n" +
			best_msg + "\n" +
			"Time used = #{Time.human_readable_timestr(logger.elapsed_time)}, " + 
			"Steps performed = #{@num_optimization_steps}, " + 
			"#{Time.human_readable_timestr(time_per_step, true)}/step")
	end

	def time_per_step
		logger.elapsed_time / logger.current_value(:NumOptimizationSteps)
	end


	def info_about_candidate(candidate, qualityValue, subQualityValues, nameString = "new")
		info_str = nameString ? "#{nameString} = #{candidate.inspect}\n  " : "  "
		info_str + candidate._quality_value.inspect
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
			log "New best candidate found", :new_best, {
				:new_best => new_best,
				:new_quality_value => new_quality_value, 
				:new_sub_qvalues => new_sub_qvalues,
				:old_best => @best,
				:old_quality_value => new_qv_old_best,
				:old_sub_qvalues => sub_qv_old_best			
			}
			@best = new_best
			@best_quality_value = new_quality_value
			@best_sub_quality_values = new_sub_qvalues
			true
		else
			false
		end
	end
end

class FeldtRuby::Optimize::PopulationBasedOptimizer < FeldtRuby::Optimize::Optimizer
	attr_reader :population

	def initialize_options(options)
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

end