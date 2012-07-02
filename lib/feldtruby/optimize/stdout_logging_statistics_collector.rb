require 'feldtruby/time'
require 'feldtruby/float'

class FeldtRuby::Optimize::StdOutLoggingStatisticsCollector
	def initialize(optimizer, verbose = true)
		@optimizer = optimizer
		@verbose = verbose
		@start_time = Time.now # To ensure we have a value even if optimizer forgot calling note_optimization_starts
	end

	def note_optimization_starts
		@start_time = Time.now
	end

	def note_new_best(newBest, newQv, newSubQvs, oldBest, oldQv, oldSubQvs)
		log_print("\n") # to get a fresh line...
		new_best_msg = "Found new best (#{quality_values_to_str(newQv, newSubQvs)})\n  new = #{newBest.inspect}"
		if oldBest
			log("#{new_best_msg},\nsupplants old best (#{quality_values_to_str(oldQv, oldSubQvs)})\n  old = #{oldBest.inspect}")
		else
			log(new_best_msg)
		end
	end

	def note_another_optimization_step(stepNumber)
		log_print(".")
	end

	def quality_values_to_str(qv, subQvs)
		"fitness = %.4f, sub_qualities = %s" % [qv, subQvs.map {|v| v.round_to_decimals(3)}.inspect]
	end

	def note_termination(message)
		log(message)
	end

	def log(str)
		if @verbose
			STDOUT.puts "#{Time.timestamp()} (#{elapsed_time()} s), #{str}"
			STDOUT.flush
		end
	end

	def log_print(str)
		if @verbose
			STDOUT.print str
			STDOUT.flush
		end
	end

	def elapsed_time
		Time.now - @start_time
	end
end