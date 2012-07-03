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
		@events = Hash.new(0)
		if verbose
			@outstream = STDOUT
		else
			@outstream = DummyStream.new
		end
	end

	def note_optimization_starts
		@start_time = Time.now
	end

	def note(msg, *values)
		@events[msg] += 1
		if (values.all? {|e| String === e})
			vstr = values.join(", ")
		else
			vstr = values.inspect
		end
		log "#{event_stat_in_relation_to_step(@events[msg])}: #{msg}\n  #{vstr})", true
	end

	def note_end_of_optimization(optimizer)
		best_msg = info_about_candidate(optimizer.best, optimizer.best_quality_value, 
			optimizer.best_sub_quality_values, "best")
		note("End of optimization!", best_msg)
	end

	def event_stat_in_relation_to_step(eventCount)
		"#{eventCount} times (%.3f times/step)" % (eventCount.to_f / num_steps)
	end

	def info_about_candidate(candidate, qualityValue, subQualityValues, nameString = "new")
		"(#{quality_values_to_str(qualityValue, subQualityValues)})\n  #{nameString} = #{candidate.inspect}"
	end

	def note_new_best(newBest, newQv, newSubQvs, oldBest, oldQv, oldSubQvs)
		new_best_msg = info_about_candidate(newBest, newQv, newSubQvs, "new")
		if oldBest
			note("Found new best!", "#{new_best_msg},\n    supplants old best (#{quality_values_to_str(oldQv, oldSubQvs)})\n  old = #{oldBest.inspect}")
		else
			note("Found new best!", new_best_msg)
		end
	end

	def note_another_optimization_step(stepNumber)
		@events['optimization steps'] += 1
		log_print(".")
	end

	def quality_values_to_str(qv, subQvs)
		"q = %.4f, subqs = %s" % [qv, subQvs.map {|v| v.round_to_decimals(3)}.inspect]
	end

	def note_termination(message)
		log(message)
	end

	def log(str, newlineBefore = false)
		@outstream.puts "" if newlineBefore
		@outstream.puts( "#{Time.timestamp({:short => true})} (%.2fs), #{str}" % elapsed_time() )
		@outstream.flush
	end

	def log_print(str)
		@outstream.print str
		@outstream.flush
	end

	def num_steps
		@events['optimization steps']
	end

	def time_per_step
		elapsed_time / num_steps
	end

	def elapsed_time
		Time.now - @start_time
	end
end