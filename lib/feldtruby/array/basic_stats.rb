class Array
	def sum
		self.inject(0) {|s, e| s+e}
	end

	def mean
		return 0 if self.length == 0
		self.sum / self.length.to_f
	end

	def average; mean(); end

	def stdev
		avg = self.mean
		Math.sqrt( self.map {|e| t = (e-avg); t*t}.sum / self.length.to_f )
	end
end