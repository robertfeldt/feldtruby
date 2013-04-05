require 'feldtruby/optimize/optimizer'

describe "PopulationBasedOptimizer" do
	before do
		@o1 = MinimizeRMS.new

		@pbo = FeldtRuby::Optimize::PopulationBasedOptimizer.new(@o1, 
			FeldtRuby::Optimize::DefaultSearchSpace,
			{:samplerClass => FeldtRuby::Optimize::PopulationSampler})	
	end

	it "has set the right population size" do
		@pbo.population_size.must_equal @pbo.options[:populationSize]
		@pbo.population.length.must_equal @pbo.options[:populationSize]
	end

	it "can reinitialize all of the population" do
		orig_population = @pbo.population.to_a.clone
		@pbo.re_initialize_population(1.0)
		@pbo.population.each do |individual|
			orig_population.include?(individual).must_equal false
		end
	end

	it "can reinitialize parts of the population" do
		[0.1, 0.25, 0.5, 0.75, 0.90].each do |p|
			orig_population = @pbo.population.to_a.clone
			@pbo.re_initialize_population(p)
			changed = 0
			@pbo.population.each do |individual|
				changed += 1 unless orig_population.include?(individual)
			end
			changed.must_equal( (p * orig_population.length).to_i )
		end
	end
end

describe "PopulationSampler" do
	before do
		@o1 = MinimizeRMS.new

		@pbo1 = FeldtRuby::Optimize::PopulationBasedOptimizer.new(@o1, 
			FeldtRuby::Optimize::DefaultSearchSpace,
			{:samplerClass => FeldtRuby::Optimize::PopulationSampler})	
	end

	it "has set the right population size" do
		@pbo1.population_size.must_equal @pbo1.options[:populationSize]
		@pbo1.population.length.must_equal @pbo1.options[:populationSize]
	end

	it "samples the right number of indices, they are in the allowed range and they are always unique" do
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

describe "RadiusLimitedPopulationSampler" do
	before do
		@o1 = MinimizeRMS.new

		@pbo1 = FeldtRuby::Optimize::PopulationBasedOptimizer.new(@o1, 
			FeldtRuby::Optimize::DefaultSearchSpace,
			{:samplerClass => FeldtRuby::Optimize::RadiusLimitedPopulationSampler})	
	end

	it "has set the right population size" do
		@pbo1.population_size.must_equal @pbo1.options[:populationSize]
	end

	it "samples the right number of indices, they are in the allowed range and they are always unique" do
		100.times do
			# We can only sample as many individuals as the samplerRadius parameter.
			num_samples = rand_int(@pbo1.options[:samplerRadius])
			sampled_indices = @pbo1.sample_population_indices_without_replacement(num_samples)
			assert_equal num_samples, sampled_indices.length
			assert_equal num_samples, sampled_indices.uniq.length, "Some elements where the same in #{sampled_indices.inspect}"
			sampled_indices.each do |i|
				assert i >= 0 && i < @pbo1.population_size
			end
		end
	end
end