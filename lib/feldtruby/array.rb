require 'feldtruby/array/basic_stats'

class Array
	def map_with_index(&block)
		index = -1 # Start below zero since we pre-increment in the loop
		self.map {|v| block.call(v,index+=1)}
	end

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

	# Prepend (or append) ranks after sorting by the value supplied from a block
	def ranks_by(prependRanks = true, &mapToValueUsedForRanking)
		res = Array.new(length)
		sorted_with_indices = self.each_with_index.map {|e,i| [i, e]}.sort_by {|v| mapToValueUsedForRanking.call(v.last)}
		sorted_with_indices.each_with_index.map do |v,index|
			orig_index, orig_element = v
			rank = length - index
			new_element = prependRanks ? ([rank] + orig_element) : (orig_element + [rank])
			res[orig_index] = new_element
		end
		res
	end

	# Add an element unless it is already in the array
	def add_unless_there(element)
		self << element unless self.include?(element)
		self
	end

	# Count elements in array and return as hash mapping elements to their counts.
	def counts
		count_hash = Hash.new(0)
		self.each {|element| count_hash[element] += 1}
		count_hash
	end

	def sample
		self[rand(self.length)]
	end
end