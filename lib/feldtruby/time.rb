def Time.timestamp(options = {:short => false})
	if options[:short]
		Time.now.strftime("%y%m%d %H:%M.%S")
	else
		Time.now.strftime("%Y%m%d %H:%M.%S")
	end
end

def Time.human_readable_timestr(seconds, insertSpace = false)
	sp = insertSpace ? " " : ""
	if seconds < 1e-4
		"%.2f#{sp}usec" % (seconds*1e6)
	elsif seconds < 1e-1
		"%.2f#{sp}msec" % (seconds*1e3)
	elsif seconds > 60*60.0
		"%.2f#{sp}hours" % (seconds/3600.0)
	elsif seconds > 60.0
		"%.2f#{sp}mins" % (seconds/60.0)
	else
		"%.2f#{sp}sec" % seconds
	end
end