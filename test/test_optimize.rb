require 'feldtruby/optimize'

class TestOptimize < MiniTest::Unit::TestCase
	def test_rosenbrock_optimization_as_in_README
		xbest, ybest = FeldtRuby::Optimize.optimize(0, 2) {|x, y|
			(1 - x)**2 + 100*(y - x*x)**2
		}
		assert_in_delta 1.0, xbest
		assert_in_delta 1.0, ybest
	end

	def in_vicinity?(x, y, delta = 0.01)
		(x-y).abs < delta
	end

	def test_himmelsblau_minimization
		# For details see: http://en.wikipedia.org/wiki/Himmelblau%27s_function
		xbest, ybest = FeldtRuby::Optimize.minimize(-5, 5, {:maxNumSteps => 5000, :verbose => false}) {|x, y|
			(x*x + y - 11)**2 + (x + y*y + - 7)**2
		}

		# There are 4 local minima:
		#   f( 3.000000,  2.000000) = 0.0
		#   f(-2.805118,  3.131312) = 0.0
		#   f(-3.779310, -3.283186) = 0.0
		#   f( 3.584428, -1.848126) = 0.0
		# and it is unlikely that we are not in the vicinity of one of those after optimization.

		if in_vicinity?(xbest, 3.000000)
			assert_in_delta 3.000000, xbest, 0.1
			assert_in_delta 2.000000, ybest, 0.1
		elsif in_vicinity?(xbest, -2.805118)
			assert_in_delta -2.805118, xbest, 0.1
			assert_in_delta 3.131312, ybest, 0.1
		elsif in_vicinity?(xbest, -3.779310)
			assert_in_delta -3.779310, xbest, 0.1
			assert_in_delta -3.283186, ybest, 0.1
		elsif in_vicinity?(xbest, 3.584428)
			assert_in_delta 3.584428, xbest, 0.1
			assert_in_delta -1.848126, ybest, 0.1
		else
			assert false, "Solution [#{xbest}, #{ybest}] is not close to any minima"
		end
	end

	def test_himmelsblau_maximization
		# There is a local maxima that can be found if we search in a smaller box around 0.0.
		# For details see: http://en.wikipedia.org/wiki/Himmelblau%27s_function
		xbest, ybest = FeldtRuby::Optimize.maximize(-1, 1, {:maxNumSteps => 2000, :verbose => false}) {|x, y|
			(x*x + y - 11)**2 + (x + y*y + - 7)**2
		}
		assert_in_delta -0.270845, xbest, 0.1
		assert_in_delta -0.923039, ybest, 0.1
	end
end
