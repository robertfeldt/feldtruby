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

	def test_bound
		s1 = FeldtRuby::Optimize::SearchSpace.new([-5, -3], [5, 7])
		assert_equal [-1, 0], s1.bound([-1, 0])

		l, h = s1.bound([-10, 3.4])
		assert_equal 3.4, h
		assert -5 <= l
		assert 5 >= l

		l, h = s1.bound([6, 2.7])
		assert_equal 2.7, h
		assert -5 <= l
		assert 5 >= l

		l, h = s1.bound([-4.6, 8.4])
		assert_equal -4.6, l
		assert -3 <= h
		assert 7 >= h

		l, h = s1.bound([-4.6, -4.1])
		assert_equal -4.6, l
		assert -3 <= h
		assert 7 >= h

		l, h = s1.bound([-60.2, 11])
		assert -5 <= l
		assert 5 >= l
		assert -3 <= h
		assert 7 >= h
	end

	def test_bound_returns_vector_if_supplied_a_vector
		s1 = FeldtRuby::Optimize::SearchSpace.new([-5, -3], [5, 7])
		b = s1.bound(Vector[-10, 5])
		assert Vector, b.class
	end
end
