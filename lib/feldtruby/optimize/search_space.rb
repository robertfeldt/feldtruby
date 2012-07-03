require 'feldtruby/optimize'

# A search space is a set of constraints that limits which values
# are searched for. The search space can generate valid candidate
# solutions that are inside the space. It can also check if a
# given candidate is in the space. The default search space has min
# and max values for each element of a continuous vector.
class FeldtRuby::Optimize::SearchSpace
	attr_reader :min_values, :max_values

	def initialize(minValues, maxValues)
		# Check that we have valid min and max values
		raise "Not same num of min values (#{minValues.length}) as there are max values (#{maxValues.length})" if minValues.length != maxValues.length
		raise "A search space must have >= 1 variable to be searched, here you specified min values: #{minValues.inspect}" if minValues.length < 1
		minValues.zip(maxValues).each do |min,max|
			raise "The min value #{min} is larger than the max value #{max} in min values = #{minValues.inspect} and #{maxValues.inspect}" if min > max
		end
		@min_values, @max_values = minValues, maxValues
		@deltas = @min_values.zip(@max_values).map {|min,max| max-min}
	end

	def self.new_symmetric(numVariables = 2, distanceFromZero = 1)
		min_values = Array.new(numVariables).map {-distanceFromZero}
		max_values = Array.new(numVariables).map {distanceFromZero}
		self.new_from_min_max(numVariables, -distanceFromZero, distanceFromZero)
	end

	def self.new_from_min_max(numVariables = 2, min = -1, max = 1)
		min_values = Array.new(numVariables).map {min}
		max_values = Array.new(numVariables).map {max}
		self.new(min_values, max_values)
	end

	def num_variables
		@min_values.length
	end

	def gen_candidate
		(0...num_variables).map {|i| gen_value_for_position(i)}
	end

	def gen_value_for_position(i)
		min, delta = @min_values[i], @deltas[i]
		min + delta * rand()
	end

	def is_candidate?(c)
		return false unless c.length == num_variables
		c.length.times do |i|
			return false unless c[i] >= min_values[i] && c[i] <= max_values[i]
		end
		return true
	end
end

FeldtRuby::Optimize::DefaultSearchSpace = FeldtRuby::Optimize::SearchSpace.new_symmetric(2, 1)