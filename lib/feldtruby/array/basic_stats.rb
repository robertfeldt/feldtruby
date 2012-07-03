module BasicStatistics
	def sum
		self.inject(0) {|s, e| s+e}
	end

	def mean
		return 0 if self.length == 0
		self.sum / self.length.to_f
	end

	def average; mean(); end

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
end

class Array
	include BasicStatistics
end