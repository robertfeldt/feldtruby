require 'feldtruby/optimize/objective'
require 'feldtruby/array'

require 'pp'

class SingleObjective1 < FeldtRuby::Optimize::Objective
	# Sum of candidate vector of values should be small
	def objective_min_small_sum(candidate)
		candidate.sum
	end
end

describe "single objective" do
	before do
		@o = SingleObjective1.new
	end

	it "has one aspect/sub-objective" do
		@o.num_aspects.must_equal 1
		@o.num_sub_objectives.must_equal 1
	end

	it "correctly calculates the quality value" do
		@o.quality_value([1]).must_equal 1
		@o.quality_value([1, 2]).must_equal 3
		@o.quality_value([1, 2, -45]).must_equal -42
	end
end

class TwoMinObjectives1 < FeldtRuby::Optimize::Objective
	def objective_min_distance_between(candidate)
		candidate.distance_between_elements.sum
	end
	def objective_min_sum(candidate)
		candidate.sum
	end
end

describe "two sub-objectives" do
	before do
		@o = TwoMinObjectives1.new
	end

  it "has two aspects/sub-objectives" do
    @o.num_aspects.must_equal 2
    @o.num_sub_objectives.must_equal 2
  end

  it "returns the global min value per aspect, which is initially at a max value since we might not now its range" do
    @o.global_min_values_per_aspect.must_equal [Float::INFINITY, Float::INFINITY]
  end

  it "returns the global max value per aspect, which is initially at a min value since we might not now its range" do
    @o.global_max_values_per_aspect.must_equal [-Float::INFINITY, -Float::INFINITY]
  end

  it "correctly updates the global min and maxs, given a sequence of updates" do
    @o.update_global_mins_and_maxs([1,2])
    @o.global_min_values_per_aspect.must_equal [1,2]
    @o.global_max_values_per_aspect.must_equal [1,2]

    @o.update_global_mins_and_maxs([1,3])
    @o.global_min_values_per_aspect.must_equal [1,2]
    @o.global_max_values_per_aspect.must_equal [1,3]

    @o.update_global_mins_and_maxs([0,8])
    @o.global_min_values_per_aspect.must_equal [0,2]
    @o.global_max_values_per_aspect.must_equal [1,8]
  end

  it "can return the vector of sub_objective values for a candidate" do
    @o.sub_objective_values([1,2]).must_equal [1,3]
    @o.sub_objective_values([1,2,4]).must_equal [3,7]
    @o.sub_objective_values([1,2,5]).must_equal [4,8]
  end

  it "correctly calculates mean-weighted-global-ratios" do
    # Lets first update so there is a spread between mins and maxs
    @o.update_global_mins_and_maxs([0, 0])
    @o.update_global_mins_and_maxs([1, 3])

    # Now check at either extreme of the interval, the quality value is always in [0.0, 1.0]
    @o.qv_mwgr([1,2]).must_equal 0.0
    @o.qv_mwgr([0,0]).must_equal 1.0
  end

  it "always returns a fitness of zero for the first call" do
    @o.fitness([1,2,3]).must_equal 0.0
  end

  it "handles a more complex series of consecutive calls" do
    # Set first values => fitness is always zero
    @o.fitness([1,2,3]).must_equal 0.0

    # Now we come with a worse candidate => still zero
    @o.fitness([1,2,5]).must_equal 0.0
    
    # But now the previous value is the best candidate we have seen so gets maximum quality value
    @o.fitness([1,2,3]).must_equal 1.0

    # The previous worst is still the worst
    @o.fitness([1,2,5]).must_equal 0.0

    # And now some complex ones that are between the prev best and worst
    @o.fitness([1,2,4]).must_equal (((4.0 - 3.0)/(4-2) + (8.0 - 7)/(8-6))/2)
    @o.fitness([1,2,4.5]).must_equal (((4.0 - 3.5)/(4-2) + (8.0 - 7.5)/(8-6))/2)

    # Now extend the global best with a new best
    @o.fitness([1,2,2]).must_equal 1.0 # new global min = [1, 5] and max the same at [4, 8]

    # And the in between candidates now have new values based on the new mins
    @o.fitness([1,2,4]).must_equal (((4.0 - 3.0)/(4-1) + (8.0 - 7)/(8-5))/2)
    @o.fitness([1,2,4.5]).must_equal (((4.0 - 3.5)/(4-1) + (8.0 - 7.5)/(8-5))/2)
  end
end

describe "the objective itself and its updates" do
	before do
		@o = SingleObjective1.new
		@o2 = TwoMinObjectives1.new
		@c = [1,2,3]
	end

	it "repeatedly returns the same quality value for an object unless the objective itself has been changed" do
		qv = @o.quality_value(@c)
		qv.must_equal @o.quality_value(@c)
	end

	it "returns different quality values for different objectives" do
		qv = @o.quality_value(@c)
		qv2 = @o2.quality_value(@c)
		qv.wont_equal qv2
	end

	it "is re-evaluated if the objective has changed since original evaluation" do
		qv = @o2.quality_value(@c)
		@o2.quality_value([1,2,3,4,5]) # Higher sum so max updated
		qvnew = @c._quality_value
		qvnew.wont_equal qv
	end

	describe "objects that have not been evaluated" do
		it "has not attached quality values" do
			c = [1,2,3]
			c._quality_value.must_equal nil
		end
	end

	describe "version numbers" do
		it "has version number 0 when no evaluation has taken place" do
			@o.current_version.must_equal 0
			@o2.current_version.must_equal 0
		end

		it "never changes the version number for a single objective since ratios are not used" do
			@o.quality_value([1])
			@o.current_version.must_equal 0			
		end

		it "increases the version number each time a quality aspect of a candidate is more extreme than previously seen (when multi-objective)" do
			@o2.quality_value([1])
			@o2.current_version.must_equal 4 # Both min and max changed for two objectives => 2*2
			@o2.quality_value([2])
			@o2.current_version.must_equal 5 # New max values for sum objective => +1
			@o2.quality_value([1,2])
			@o2.current_version.must_equal 7 # New max values for both objectives => +2
			@o2.quality_value([0])
			@o2.current_version.must_equal 8 # New min value for sum objective => +1
			@o2.quality_value([-1])
			@o2.current_version.must_equal 9 # New min value for sum objective => +1
			@o2.quality_value([-2])
			@o2.current_version.must_equal 10 # New min value for sum objective => +1
			@o2.quality_value([1,2,3])
			@o2.current_version.must_equal 12 # New max for both objectives => +1
		end
	end
end
