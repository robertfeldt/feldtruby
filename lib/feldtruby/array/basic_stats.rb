module BasicStatistics
	def sum
		self.inject(0) {|s, e| s+e}
	end

	def mean
		return 0 if self.length == 0
		self.sum / self.length.to_f
	end

	def average; mean(); end

	def median
		return nil if length == 0
		sorted = self.sort
		if self.length % 2 == 0
			mid = self.length / 2
			(sorted[mid-1] + sorted[mid])/2.0
		else
			sorted[self.length/2.0]
		end
	end

	def variance
		return 0 if self.length == 0
		avg = self.mean
		self.map {|e| (e-avg)**2}.sum / self.length.to_f
	end

	def stdev
		Math.sqrt( self.variance )
	end

	def root_mean_square
		Math.sqrt( self.map {|v| v**2}.mean )
	end

	def rms; self.root_mean_square(); end

	def rms_from_scalar(scalar)
		Math.sqrt( self.map {|v| (v-scalar)**2}.mean )		
	end

	# Weighted sum of elements
	def weighted_sum(weights = nil)
		if weights
			raise "Not same num of weights (#{weights.length}) as num of elements (#{self.length})" if self.length != weights.length
			self.zip(weights).map {|e,w| e*w}.sum
		else
			self.sum
		end
	end

	# Weighted mean of elements
	def weighted_mean(weights = nil)
		if weights
			self.weighted_sum(weights) / weights.sum.to_f
		else
			self.mean
		end
	end

	def sum_of_abs_deviations(fromValue = 0.0)
		sum = 0.0
		self.each {|v| sum += (v-fromValue).abs}
		sum
	end

	def sum_of_abs
		sum = 0.0
		self.each {|v| sum += v.abs}
		sum
	end

	def sum_squared_error(b)
		sum = 0.0
		self.each_with_index {|e,i| d = e-b[i]; sum += d*d}
		sum
	end

	# Return summary stats for an array of numbers.
	def summary_stats
 		"%.3f (min = %.1f, max = %.1f, median = %.1f, stdev = %.2f)" % [mean, self.min, self.max, median, stdev]
 	end
end

class Array
	include BasicStatistics
end