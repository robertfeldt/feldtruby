require 'feldtruby/optimize'

class TestOptimize < MiniTest::Unit::TestCase
	def test_rosenbrock_optimization_as_in_README
		xbest, ybest = FeldtRuby::Optimize.optimize(2, 0, 2) {|x, y|
			(1 - x)**2 + 100*(y - x*x)**2
		}
		assert_in_delta 1.0, xbest
		assert_in_delta 1.0, ybest
	end
end
