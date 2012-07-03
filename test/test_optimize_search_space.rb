require 'feldtruby/optimize/search_space'

class TestSearchSpace < MiniTest::Unit::TestCase
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
end
