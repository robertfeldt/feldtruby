require 'feldtruby/optimize'

module FeldtRuby::Optimize

# A search space is a set of constraints that limits which values
# are searched for. The search space can generate valid candidate
# solutions that are inside the space. It can also check if a
# given candidate is in the space. The default search space has min
# and max values for each element of a continuous vector.
class SearchSpace
	attr_reader :min_values, :max_values, :deltas

	def initialize(minValues, maxValues, sampler = LatinHypercubeSampler.new)
		sampler.search_space = self
		@sampler = sampler
		# Check that we have valid min and max values
		raise "Not same num of min values (#{minValues.length}) as there are max values (#{maxValues.length})" if minValues.length != maxValues.length
		raise "A search space must have >= 1 variable to be searched, here you specified min values: #{minValues.inspect}" if minValues.length < 1
		minValues.zip(maxValues).each do |min,max|
			raise "The min value #{min} is larger than the max value #{max} in min values = #{minValues.inspect} and #{maxValues.inspect}" if min > max
		end
		@min_values, @max_values = minValues, maxValues
		@deltas = @min_values.zip(@max_values).map {|min,max| max-min}
	end

	# Generate a new candidate.
	def gen_candidate
		@sampler.sample_candidate
	end

	def gen_value_for_position(index)
		@sampler.sample_value_for_dimension(index)
	end

	# Bound candidate using the min and max values. We randomly generate a new value inside the space
	# for each element that is outside.
	def bound(candidate)
		a = candidate.each_with_index.map do |v, i|
			in_range_for_position?(v, i) ? v : gen_value_for_position(i)
		end
		candidate.class.send(:[], *a)
	end

	def in_range_for_position?(value, index)
		(value >= @min_values[index]) && (value <= @max_values[index])
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

	# A sampler generates a new candidate, or set of candidates, that is/are within a search space. This default
	# sampler is uniform random over the whole search space.
	class Sampler
		attr_accessor :search_space

		def initialize(searchSpace = nil)
			self.search_space = searchSpace
		end

		# Randomly sample a valid value for a given dimension index in the search space.
		def sample_value_for_dimension(index)
			min, delta = search_space.min_values[index], search_space.deltas[index]
			min + delta * rand()
		end

		# Sample one candidate within the space. Default is to do random uniform sampling.
		def sample_candidate
			num_vars = search_space.num_variables
			(0...num_vars).map {|i| sample_value_for_dimension(i)}
		end

		# Sample multiple candidates from the search space. The default is just to call the method sampling one
		# candidate mutliple times. But subclasses can implement more sophisticated schemes.
		def sample_candidates(numCandidates)
			Array.new(numCandidates) { sample_candidate() }
		end
	end

	# Set samplers sample many candidates in one go, often to create a better "spread" of genotypes within
	# the search space.
	class SetSampler < Sampler
		# The chunk size is the number of candidates that are generated in one go and from which the individual
		# candidates are then taken. Default is 100 to get a nice spread.
		def initialize(chunkSize = 100)
			@chunk_size = chunkSize
			@chunk = []
		end

		# Sample a set of candidates.
		def sample_candidates(numCandidates)
			raise NotImplementedError # Subclasses must implement this
		end

		def sample_candidate
			sample_new_chunk() if chunk_empty?
			pop_candidate_from_chunk()
		end

		def sample_new_chunk
			@chunk = sample_candidates(@chunk_size)
		end

		def chunk_empty?
			@chunk.nil? || @chunk.length < 1
		end

		def pop_candidate_from_chunk
			@chunk.pop
		end
	end

	class LatinHypercubeSampler < SetSampler
		# Sample the latin hypercube evenly for each dimension in the search space and then
		# use Knuth unbiased shuffling to create individuals from the evenly spread out samples.
		def sample_candidates(numCandidates)
			set = Array.new(numCandidates).map {Array.new}
			(0...(search_space.num_variables)).each do |dimension|
				samples = latin_samples_for_dimension(dimension, numCandidates)
				pi = (0...numCandidates).to_a.shuffle  # Ruby has Knuth shuffle built in so no need to implement
				(0...numCandidates).each {|i| set[i] << samples[pi[i]]}
			end
			set
		end

		# Evenly spread _numSamples_ random samples over the search space dimension with _index_.
		def latin_samples_for_dimension(index, numSamples)
			low, delta = search_space.min_values[index], search_space.deltas[index]
			interval_size = delta / numSamples.to_f
			i = 0
			Array.new(numSamples).map do
				i += 1
				(low + (i-1) * interval_size) + (interval_size * rand())
			end
		end
	end

	def is_candidate?(c)
		return false unless c.length == num_variables
		c.length.times do |i|
			return false unless c[i] >= min_values[i] && c[i] <= max_values[i]
		end
		return true
	end
end

DefaultSearchSpace = SearchSpace.new_symmetric(2, 1)

end