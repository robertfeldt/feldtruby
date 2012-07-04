require 'feldtruby/array/basic_stats'

class Array
	# Calculate the distance between the elements.
	def distance_between_elements
		return nil if self.length == 0
		self[0...-1].zip(self[1..-1]).map {|x,y| y-x}
	end

	# Swap two elements given their indices. Assumes both indices are in range.
	def swap!(index1, index2)
		self[index1], self[index2] = self[index2], self[index1]
	end

	# Rank of values in array from 1..length
	def ranks
		ranks = Array.new(length)
		self.each_with_index.map {|e,i| [i, e]}.sort_by {|v| v.last}.each_with_index.map {|v,i| ranks[v.first]=length-i}
		ranks
	end
end