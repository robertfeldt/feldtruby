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

	# Calculate the values that cuts the data into 0%, 25%, 50%, 75% and 100%.
	# This corresponds to the min, 1st quartile, 2nd quartile, 3rd quartile and the max.
	def quantiles
		return [nil, nil, nil, nil, nil] if length == 0
		sorted = self.sort
		q1 = sorted.quantile_at_ratio(0.25)
		q2 = sorted.quantile_at_ratio(0.50)
		q3 = sorted.quantile_at_ratio(0.75)
		return sorted.first, q1, q2, q3, sorted.last
	end

	# Calculate the quantile at a given ratio (must be between 0.0 and 1.0) assuming self
	# is a sorted array. This is based on the type 7 quantile function in R.
	def quantile_at_ratio(p)
		n = self.length
		h = (n - 1) * p + 1
		hfloor = h.floor
		if h == hfloor
			self[hfloor-1]
		else
			x_hfloor = self[hfloor-1]
			x_hfloor + (h - hfloor)*(self[hfloor] - x_hfloor)
		end
	end

	# Calculate the three quartiles of the array.
	def quartiles
		return [nil, nil, nil] if length == 0
		sorted = self.sort
		q1 = sorted.quantile_at_ratio(0.25)
		q2 = sorted.quantile_at_ratio(0.50)
		q3 = sorted.quantile_at_ratio(0.75)
		return q1, q2, q3
	end

	def inter_quartile_range
		q1, q2, q3 = quartiles
		q3 - q1
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