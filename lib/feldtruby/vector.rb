require 'matrix'
require 'feldtruby/array/basic_stats'

class Vector
	# length is used by the BasicStatistics methods but is not available in Vector so add it...
	def length; size(); end
	include BasicStatistics
end