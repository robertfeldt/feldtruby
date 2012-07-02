require 'feldtruby/time'
require 'feldtruby/float'

class FeldtRuby::Optimize::StdOutLoggingStatisticsCollector
	class DummyStream
		def puts(str); end
		def print(str); end
		def flush(); end
	end

	def initialize(optimizer, verbose = true)
		@optimizer = optimizer
		@verbose = verbose
		@start_time = Time.now # To ensure we have a value even if optimizer forgot calling note_optimization_starts
		if verbose
			@outstream = STDOUT
		else
			@outstream = DummyStream.new
		end
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
		@outstream.puts( "#{Time.timestamp({:short => true})} (%.2fs), #{str}" % elapsed_time() )
		@outstream.flush
	end

	def log_print(str)
		@outstream.print str
		@outstream.flush
	end

	def elapsed_time
		Time.now - @start_time
	end
end