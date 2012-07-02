require 'feldtruby/optimize'
require 'feldtruby/optimize/objective'
require 'feldtruby/optimize/search_space'
require 'feldtruby/optimize/stdout_logging_statistics_collector'
require 'feldtruby/optimize/max_steps_termination_criterion'

DefaultOptimizationOptions = {
	:statisticsCollector => FeldtRuby::Optimize::StdOutLoggingStatisticsCollector,
	:terminationCriterion => FeldtRuby::Optimize::MaxStepsTerminationCriterion.new(1000),
	:verbose => true
}

# Find an vector of float values that optimizes a given
# objective.
class FeldtRuby::Optimize::Optimizer
	attr_reader :objective, :search_space, :best, :best_quality_value, :num_optimization_steps, :termination_criterion

	def initialize(objective, searchSpace = FeldtRuby::Optimize::DefaultSearchSpace, options = {})
		@objective, @search_space = objective, searchSpace
		@options = DefaultOptimizationOptions.update(options)
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