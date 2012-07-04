require 'matrix'
require 'feldtruby/array/basic_stats'

class Vector
	# length is used by the BasicStatistics methods but is not available in Vector so add it...
	def length; size(); end
	include BasicStatistics

	# Override index method and add slicing.
	def [](index, length = nil)
		return @elements[index] unless length
		Vector.elements(self.to_a[index, length])
	end
end