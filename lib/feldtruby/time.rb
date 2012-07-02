def Time.timestamp(options = {:short => false})
	if options[:short]
		Time.now.strftime("%y%m%d %H:%M.%S")
	else
		Time.now.strftime("%Y%m%d %H:%M.%S")
	end
end