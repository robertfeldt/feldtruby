class Array
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
end