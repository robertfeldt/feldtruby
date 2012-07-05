require 'feldtruby/time'
require 'feldtruby/float'

class FeldtRuby::Optimize::StdOutLogger
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
		@last_report_time = Hash.new(Time.new("1970-01-01")) # Maps event strings to the last time they were reported on, used by anote.
		if verbose
			@outstream = STDOUT
		else
			@outstream = DummyStream.new
		end
	end

	def note_optimization_starts
		log("Optimization with optimizer #{@optimizer.class.inspect} started")
		@start_time = Time.now
	end

	def internal_note(shouldPrint, msg, values)
		@events[msg] += 1
		if (values.all? {|e| String === e})
			vstr = values.join("\n  ")
		else
			vstr = values.inspect
		end
		if msg == "."
			# Just a tick so no event stat etc
			log_print( msg ) if shouldPrint
		else
			log( "#{event_stat_in_relation_to_step(@events[msg])}: #{msg}\n  #{vstr}", true ) if shouldPrint
		end
	end

	def note(msg, *values)
		internal_note true, msg, values
	end

	# Adaptive notes are recorded as any (normal) notes but is only reported to the user in a readable
	# manner i.e. the frequency of reporting them is limited.
	def adaptive_note(frequency, msg, values = [])
		should_print = elapsed_since_last_reporting_of(msg) > frequency
		@last_report_time[msg] = Time.now if should_print
		internal_note should_print, msg, values
	end

	def anote(msg, *values)
		adaptive_note(2.0, msg, values)
	end

	def elapsed_since_last_reporting_of(msg)
		Time.now - @last_report_time[msg]
	end

	def note_end_of_optimization(optimizer)
		best_msg = info_about_candidate(optimizer.best, optimizer.best_quality_value, 
			optimizer.best_sub_quality_values, "best")
		note("End of optimization", "Optimizer: #{optimizer.class}", 
			best_msg, 
			event_summary_to_str(),
			"Time used = #{Time.human_readable_timestr(elapsed_time)}, " + 
			"Steps performed = #{num_steps}, " + 
			"#{Time.human_readable_timestr(time_per_step, true)}/step")
	end

	def event_summary_to_str()
		"Event counts:\n    " + @events.to_a.map {|key,count| "#{key}: #{event_stat_in_relation_to_step(count)}"}.join("\n    ")
	end

	def event_stat_in_relation_to_step(eventCount)
		"#{eventCount} times (%.3f times/step)" % (eventCount.to_f / num_steps)
	end

	def info_about_candidate(candidate, qualityValue, subQualityValues, nameString = "new")
		info_str = nameString ? "#{nameString} = #{candidate.inspect}\n  " : "  "
		info_str + candidate._quality_value.inspect
	end

	def note_new_better(betterMsg, newBetter, newQv, newSubQvs)
		new_better_msg = info_about_candidate(newBetter, newQv, newSubQvs, nil)
		anote(betterMsg, new_better_msg)
	end

	def note_new_best(newBest, newQv, newSubQvs, oldBest = nil, oldQv = nil, oldSubQvs = nil)
		new_best_msg = info_about_candidate(newBest, newQv, newSubQvs, "new")
		if oldBest
			new_best_msg += ",\n  supplants old best\n  #{oldQv.inspect}"
			new_best_msg += "\n  #{newQv.improvement_in_relation_to(oldQv)}\n"
		end
		anote("Found new best", new_best_msg)
	end

	def note_another_optimization_step(stepNumber)
		@events['Optimization steps'] += 1 # we note it by hand since we are printing something different than the event name
		adaptive_note(0.1, '.')
	end

	def quality_values_to_str(qv, subQvs)
		"q = %.4f, subqs = %s" % [qv, subQvs.map {|v| v.round_to_decimals(4)}.inspect]
	end

	def note_termination(message)
		log(message, true)
	end

	def log(str, newlineBefore = false, newlineAfter = true)
		@outstream.puts "" if newlineBefore
		@outstream.print "#{Time.timestamp({:short => true})} #{num_steps}: (#{Time.human_readable_timestr(elapsed_time)}), #{str}"
		@outstream.puts "" if newlineAfter
		@outstream.flush
	end

	def log_print(str)
		@outstream.print str
		@outstream.flush
	end

	def num_steps
		@events['Optimization steps']
	end

	def time_per_step
		elapsed_time / num_steps
	end

	def elapsed_time
		Time.now - @start_time
	end
end