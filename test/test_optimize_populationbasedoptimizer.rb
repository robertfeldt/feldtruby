require 'feldtruby/optimize/optimizer'

class TestPopulationBasedOptimizer < MiniTest::Unit::TestCase
	def setup
		@o1 = MinimizeRMS.new
		@pbo1 = FeldtRuby::Optimize::PopulationBasedOptimizer.new(@o1)	
	end

	def test_population_size
		assert_equal 100, @pbo1.population_size
	end

	def test_sample_population_indices_without_replacement
		100.times do
			num_samples = rand_int(@pbo1.population_size)
			sampled_indices = @pbo1.sample_population_indices_without_replacement(num_samples)
			assert_equal num_samples, sampled_indices.length
			assert_equal num_samples, sampled_indices.uniq.length, "Some elements where the same in #{sampled_indices.inspect}"
			sampled_indices.each do |i|
				assert i >= 0 && i < @pbo1.population_size
			end
		end
	end
end
