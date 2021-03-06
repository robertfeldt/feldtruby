require 'minitest/spec'
require 'feldtruby/optimize/search_space'

describe "SearchSpace#bound" do
	before do
		@sp = FeldtRuby::Optimize::SearchSpace.new([-5, -3], [5, 7])
	end

	it "returns the values if they are INSIDE the search space boundaries" do
		@sp.bound([-1, 0]).must_equal [-1, 0]
	end

	it "returns the values if they are ON the search space boundaries" do
		@sp.bound([-5, -3]).must_equal 	[-5, -3]
		@sp.bound([5, 7]).must_equal 		[5, 7]
		@sp.bound([-5, 7]).must_equal 	[-5, 7]
		@sp.bound([5, -3]).must_equal 	[5, -3]
	end

	it "generates a value INSIDE the search space boundaries when a value is given that is outside (negative, outside on one dimension)" do
		l, h = @sp.bound([-10, 3.4])
		h.must_equal 3.4
		l.must_be :>=, -5
		l.must_be :<=,  5

		l, h = @sp.bound([-4.6, -4.1])
		l.must_equal(-4.6)
		h.must_be :>=, -3
		h.must_be :<=,  7
	end

	it "generates a value INSIDE the search space boundaries when a value is given that is outside (positive, outside on one dimension)" do
		l, h = @sp.bound([6, 2.7])
		h.must_equal 2.7
		l.must_be :>=, -5
		l.must_be :<=,  5

		l, h = @sp.bound([-4.6, 8.4])
		l.must_equal(-4.6)
		h.must_be :>=, -3
		h.must_be :<=,  7
	end

	it "generates a value INSIDE the search space boundaries when a value is given that is outside (positive, outside on one dimension)" do
		l, h = @sp.bound([-60.2, 1])
		l.must_be :>=, -5
		l.must_be :<=,  5
		h.must_be :>=, -3
		h.must_be :<=,  7
	end
end

describe "SearchSpace#bound_at_index" do
	before do
		@sp = FeldtRuby::Optimize::SearchSpace.new([-5, -3], [5, 7])
	end

	it "returns the values if they are INSIDE the search space boundaries" do
		@sp.bound_at_index(0, [-1, 0]).must_equal [-1, 0]
		@sp.bound_at_index(1, [-1, 0]).must_equal [-1, 0]
	end

	it "returns the values if they are ON the search space boundaries" do
		@sp.bound_at_index(0, [-5, -3]).must_equal [-5, -3]
		@sp.bound_at_index(1, [-5, -3]).must_equal [-5, -3]
		@sp.bound_at_index(0, [ 5,  7]).must_equal [ 5,  7]
		@sp.bound_at_index(1, [ 5,  7]).must_equal [ 5,  7]
	end

	it "generates a value INSIDE the search space boundaries when a value is given that is outside (negative, outside on one dimension)" do
		l, h = @sp.bound_at_index(0, [-10, 3.4])
		h.must_equal 3.4
		l.must_be :>=, -5
		l.must_be :<=,  5

		l, h = @sp.bound_at_index(1, [-4.6, -4.1])
		l.must_equal(-4.6)
		h.must_be :>=, -3
		h.must_be :<=,  7
	end

  it "does not touch a value outside the boundaries if it is not at the index" do
		@sp.bound_at_index(1, [-10, 3.4]).must_equal [-10, 3.4]
		@sp.bound_at_index(0, [-4.6, -4.1]).must_equal [-4.6, -4.1]
  end  
end

describe "LatinHypercubeSampler" do
	before do
		@sampler = FeldtRuby::Optimize::SearchSpace::LatinHypercubeSampler.new
		@sp = FeldtRuby::Optimize::SearchSpace.new([0, 2], [1, 5], @sampler)
	end

	it "has been linked up to the search space" do
		@sampler.search_space.must_equal @sp
	end

	it "can generate a set of two valid candidates from a search space and they are properly spread out" do
		100.times do
			set = @sampler.sample_candidates(2)
			set.must_be_instance_of Array
			set.length.must_equal 2
			c1, c2 = set
			if c1[0] < 0.5
				c2[0].must_be :>=, 0.5
				c1[0].must_be :>=, 0.0
			else
				c2[0].must_be :<, 0.5
				c1[0].must_be :<, 1.0
			end
			if c1[1] < 3.5
				c2[1].must_be :>=, 3.5
				c1[1].must_be :>=, 2.0
			else
				c2[1].must_be :<, 3.5
				c1[1].must_be :<, 5.0
			end
		end
	end

	it "can generate a single candidate that are within the search space" do
		100.times do
			c = @sampler.sample_candidate
			c.must_be_instance_of Array
			c.length.must_equal 2
			c[0].must_be :>=, 0.0
			c[0].must_be :<, 1.0
			c[1].must_be :>=, 2.0
			c[1].must_be :<, 5.0
		end
	end

	it "does not return the same candidate twice even if generating a single candidate" do
		100.times do
			c1 = @sampler.sample_candidate
			c2 = @sampler.sample_candidate
			c1.wont_equal c2
		end
	end
end

describe "SearchSpace.new_from_min_max_per_variable" do
	it "can generate a valid search space from min max per variable" do
		ss = FeldtRuby::Optimize::SearchSpace.new_from_min_max_per_variable([[0, 6], [-3, 2], [17, 100]])
		ss.num_variables.must_equal 3
		ss.min_values.must_equal [0, -3, 17]
		ss.max_values.must_equal [6, 2, 100]
	end

	it "raises an exception if there are no min max pairs in the supplied array" do
		proc {
			FeldtRuby::Optimize::SearchSpace.new_from_min_max_per_variable([])
			}.must_raise(RuntimeError)
	end
end

class TestSearchSpace < Minitest::Test
	def setup
		@s1 = FeldtRuby::Optimize::SearchSpace.new([-5], [5])	
		@s2 = FeldtRuby::Optimize::SearchSpace.new([-1, -1], [1, 1])	
		@s3 = FeldtRuby::Optimize::SearchSpace.new([-1, -5, -100], [1, 50, 1000])	
		@s4 = FeldtRuby::Optimize::SearchSpace.new_symmetric(4, 10)
	end

	def test_num_variables
		assert_equal 1, @s1.num_variables
		assert_equal 2, @s2.num_variables
		assert_equal 3, @s3.num_variables
		assert_equal 4, @s4.num_variables
	end

	def assert_gen_candidate_and_is_candidate(ss, numRepetitions = 100)
		numRepetitions.times do
			c = ss.gen_candidate()
			assert_equal ss.num_variables, c.length
			c.length.times do |i| 
				assert ss.min_values[i] <= c[i]
				assert ss.max_values[i] >= c[i]
			end
			assert ss.is_candidate?(c)
		end
	end

	def test_gen_candidate_and_is_candidate
		assert_gen_candidate_and_is_candidate(@s1)
		assert_gen_candidate_and_is_candidate(@s2)
		assert_gen_candidate_and_is_candidate(@s3)
		assert_gen_candidate_and_is_candidate(@s4)
	end

	def test_new_from_min_max
		ss = FeldtRuby::Optimize::SearchSpace.new_from_min_max(2, -7, 2)
		assert_equal 2, ss.num_variables
	end

	def test_bound_returns_vector_if_supplied_a_vector
		s1 = FeldtRuby::Optimize::SearchSpace.new([-5, -3], [5, 7])
		b = s1.bound(Vector[-10, 5])
		assert Vector, b.class
	end
end
