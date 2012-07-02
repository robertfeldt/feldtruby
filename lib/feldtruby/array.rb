require 'feldtruby/array/basic_stats'

class Array
	# Calculate the distance between the elements.
	def distance_between_elements
		return nil if self.length == 0
		self[0...-1].zip(self[1..-1]).map {|x,y| y-x}
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
end