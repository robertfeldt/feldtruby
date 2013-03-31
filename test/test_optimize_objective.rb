require 'feldtruby/minitest_extensions'
require 'feldtruby/optimize/objective'
require 'feldtruby/array'
require 'pp'

class SingleObjective1 < FeldtRuby::Optimize::Objective
  # Sum of candidate vector of values should be as small as possible
  def goal_min_sum(candidate)
    candidate.sum
  end
end

describe "a single minimizing objective" do
	before do
		@o = SingleObjective1.new
	end

	it "has one goal" do
		@o.num_goals.must_equal 1
	end

  it "can return the name of the goal methods" do
    @o.goal_methods.sort.must_equal [:goal_min_sum]
  end

  it "can indicate if a method is a min method" do
    @o.is_min_goal?(0).must_equal true
  end

  it "can detect valid and invalid aspect/sub_objective names" do
    @o.is_goal_method?("goal_min_anything").must_equal true
    @o.is_goal_method?("goal_max_anything").must_equal true
    @o.is_goal_method?("goal_min_very_complex_names_are_not_a_problem").must_equal true
    @o.is_goal_method?("min_anything").must_equal false
    @o.is_goal_method?("max_anything").must_equal false
  end

  it "can detect valid and invalid minimization aspect/sub_objective names" do
    @o.is_min_goal_method?("goal_min_anything").must_equal true
    @o.is_min_goal_method?("goal_min_very_complex_names_are_not_a_problem").must_equal true
    @o.is_min_goal_method?("goal_max_anything").must_equal false
    @o.is_min_goal_method?("min_anything").must_equal false
    @o.is_min_goal_method?("max_anything").must_equal false
  end

	it "correctly calculates the sub-qualitites" do
		@o.sub_qualities_of([1]).must_equal [1]
		@o.sub_qualities_of([1, 2]).must_equal [3]
		@o.sub_qualities_of([1, 2, -45]).must_equal [-42]
	end

	it "correctly calculates the quality value and sets up its getter methods" do
		i1 = [1]
    q1 = @o.quality_of(i1)
    q1.value.must_equal 1
    q1.sub_qualities.must_equal [1]
    q1.candidate.must_equal i1
    q1.objective.must_equal @o
    q1.version.must_equal @o.current_version

    i2 = [1, 2]
		q2 = @o.quality_of(i2)
    q2.value.must_equal 3
    q2.sub_qualities.must_equal [3]
    q2.candidate.must_equal i2
    q2.objective.must_equal @o
    q2.version.must_equal @o.current_version

    i3 = [1, 2, -45]
		q3 = @o.quality_of(i3)
    q3.value.must_equal -42
    q3.sub_qualities.must_equal [-42]
    q3.candidate.must_equal i3
    q3.objective.must_equal @o
    q3.version.must_equal @o.current_version
	end
end

class TwoMinObjectives1 < FeldtRuby::Optimize::Objective
	def objective_min_distance_between(candidate)
		candidate.distance_between_elements.sum
	end
	def objective_min_sum(candidate)
		candidate.sum
	end

  public :update_global_mins_and_maxs
end

describe "two sub-objectives" do
	before do
		@o = TwoMinObjectives1.new
	end

  it "has two aspects/sub-objectives" do
    @o.num_goals.must_equal 2
  end

  it "can return the names of the goal methods" do
    @o.goal_methods.sort.must_equal [:objective_min_distance_between, :objective_min_sum]
  end

  it "can indicate if the method are min methods" do
    @o.is_min_goal?(0).must_equal true
    @o.is_min_goal?(1).must_equal true
  end

  it "returns the global min value per aspect, which is initially at a max value since we might not now its range" do
    @o.global_min_values_per_aspect.must_equal [Float::INFINITY, Float::INFINITY]
  end

  it "returns the global max value per aspect, which is initially at a min value since we might not now its range" do
    @o.global_max_values_per_aspect.must_equal [-Float::INFINITY, -Float::INFINITY]
  end

  it "correctly updates the global min and maxs, given a sequence of updates" do
    i1 = [1,2]
    @o.update_global_mins_and_maxs([1,3], i1)
    @o.global_min_values_per_aspect.must_equal [1,3]
    @o.global_max_values_per_aspect.must_equal [1,3]

    i2 = [1,3]
    @o.update_global_mins_and_maxs([2,4], i2)
    @o.global_min_values_per_aspect.must_equal [1,3]
    @o.global_max_values_per_aspect.must_equal [2,4]

    i3 = [2,2,2,2]
    @o.update_global_mins_and_maxs([0,8], i3)
    @o.global_min_values_per_aspect.must_equal [0,3]
    @o.global_max_values_per_aspect.must_equal [2,8]
  end

  it "can return the vector of sub_objective values for a candidate" do
    @o.sub_qualities_of([1,2]).must_equal [1,3]
    @o.sub_qualities_of([1,2,4]).must_equal [3,7]
    @o.sub_qualities_of([1,2,5]).must_equal [4,8]
  end

  it "correctly calculates the quality value and updates version numbers" do
    i1 = [1,2,3]
    q1 = @o.quality_of(i1)
    q1.value.must_equal( 1*((2-1) + (3-2)) + 1*(1+2+3) )
    q1.sub_qualities.must_equal [2.0, 6.0]
    q1.candidate.must_equal i1
    q1.objective.must_equal @o
    q1.version.must_equal @o.current_version
    @o.best_candidate.must_equal i1

    i2 = [2,2,2]
    q2 = @o.quality_of(i2)
    q2.value.must_equal( 1*0 + 1*6 )
    q2.sub_qualities.must_equal [0.0, 6.0]
    q2.candidate.must_equal i2
    q2.objective.must_equal @o
    q2.version.must_equal @o.current_version
    # Since 0.0 was smaller than previous minimum for goal 1 the version number 
    # should be updated since the quality eval above.
    q2.version.must_equal( q1.version + 1 )
    @o.best_candidate.must_equal i2

    i3 = [2,2,10]
    q3 = @o.quality_of(i3)
    q3.value.must_equal( 1*8 + 1*14 )
    q3.sub_qualities.must_equal [8.0, 14.0]
    q3.candidate.must_equal i3
    q3.objective.must_equal @o
    q3.version.must_equal @o.current_version
    # Since both goals got new max values the version number should have
    # been bumped by 2.
    q3.version.must_equal( q2.version + 2 )

    @o.best_candidate.must_equal i2
  end

  it "handles a more complex series of consecutive calls" do
    @o.quality_of([1,2,3]).value.must_equal 8.0

    # Now we come with a worse candidate
    @o.quality_of([1,2,5]).value.must_equal 12.0

    # Previous candidates still has same quality.
    @o.quality_of([1,2,3]).value.must_equal 8.0
    @o.quality_of([1,2,5]).value.must_equal 12.0

    # And now some complex ones that are between the prev best and worst
    @o.quality_of([1,2,4]).value.must_equal 10.0
    @o.quality_of([1,2,4.5]).value.must_equal 11.0
  end

  it "correctly ranks candidates" do
    i1 = [1,2,3,4]
    i2 = [1,1,2,2]
    i3 = [0,0,10,20]

    res = @o.rank_candidates([i1, i2, i3])
    res.first.must_equal i2
    res.last.must_equal i3
    res[1].must_equal i1
    res.length.must_equal 3

    q1 = i1._annotations[@o][:quality]
    q1.version.must_equal @o.current_version

    q2 = i2._annotations[@o][:quality]
    q1.version.must_equal @o.current_version

    q3 = i3._annotations[@o][:quality]
    q3.version.must_equal @o.current_version
  end

  it "updates the quality value if old when calling quality_of" do
    i1 = [1,2,3]
    q1 = @o.quality_of(i1)
    i2 = [1,1,1]
    q2 = @o.quality_of(i2)
    q1b = @o.quality_of(i1)
    q1b.version.must_equal q2.version
  end

  it "updates the quality value if old when calling rank_candidates" do
    i1 = [1,2,3]
    q1 = @o.quality_of(i1)
    i2 = [1,1,1]

    res = @o.rank_candidates([i1, i2])

    q1 = i1._annotations[@o][:quality]
    q1.version.must_equal @o.current_version

    q2 = i2._annotations[@o][:quality]
    q1.version.must_equal @o.current_version
  end
end

describe "the objective itself and its updates" do
	before do
		@o = SingleObjective1.new
		@o2 = TwoMinObjectives1.new
		@c = [1,2,3]
	end

	it "repeatedly returns the same quality value for an object unless the objective itself has been changed" do
		qv = @o.quality_of(@c)
		qv.must_equal @o.quality_of(@c)
	end

	it "returns different quality values for different objectives" do
		qv = @o.quality_of(@c)
		qv2 = @o2.quality_of(@c)
		qv.wont_equal qv2
	end

	it "re-evaluates if the objective has changed since original evaluation" do
		qv = @o2.quality_of(@c)
		@o2.quality_of([1,2,3,4,5]) # Higher sum so max updated
		qvnew = @o2.quality_of(@c)
		qvnew.wont_equal qv
	end

  it "can compare two candidates directly" do
    @o.is_better_than?([1], [2]).must_equal true
    @o.is_better_than?([3], [2]).must_equal false

    # If they have the same quality value the result can be arbitrary
    # but in the current implementation it is not:
    @o.is_better_than?([3, 1], [2, 2]).must_equal true
  end

	describe "version numbers" do
		it "has version number 0 when no evaluation has taken place" do
			@o.current_version.must_equal 0
			@o2.current_version.must_equal 0
		end

		it "increases the version number also for single goal objectives" do
			@o.quality_of([1])
			@o.current_version.must_equal 2 # min and max changed
		end

		it "increases the version number each time a quality aspect of a candidate is more extreme than previously seen (when multi-objective)" do
			@o2.quality_of([1])
			@o2.current_version.must_equal 4 # Both min and max changed for two objectives => 2*2
			@o2.quality_of([2])
			@o2.current_version.must_equal 5 # New max values for sum objective => +1
			@o2.quality_of([1,2])
			@o2.current_version.must_equal 7 # New max values for both objectives => +2
			@o2.quality_of([0])
			@o2.current_version.must_equal 8 # New min value for sum objective => +1
			@o2.quality_of([-1])
			@o2.current_version.must_equal 9 # New min value for sum objective => +1
			@o2.quality_of([-2])
			@o2.current_version.must_equal 10 # New min value for sum objective => +1
			@o2.quality_of([1,2,3])
			@o2.current_version.must_equal 12 # New max for both objectives => +1
		end
	end
end

class OneMinOneMaxObjective1 < FeldtRuby::Optimize::Objective
  def objective_min_distance_between(candidate)
    candidate.distance_between_elements.sum
  end
  def objective_max_sum(candidate)
    candidate.sum
  end
end

describe "two sub-objectives, one min and one max" do
  before do
    @o = OneMinOneMaxObjective1.new
  end

  it "has two aspects/sub-objectives" do
    @o.num_goals.must_equal 2
  end

  it "can return the names of the goal methods" do
    @o.goal_methods.sort.must_equal [:objective_max_sum, :objective_min_distance_between]
  end

  it "can indicate if the method are min methods" do
    @o.is_min_goal?(0).must_equal true
    @o.is_min_goal?(1).must_equal false
  end
end

describe "calculating quality when there is one max goal" do
  before do
    @o = OneMinOneMaxObjective1.new
  end

  it "inverts the max value so that it grows downwards" do
    i1 = [1,2,3]
    q1 = @o.quality_of(i1)
    q1.value.must_equal( ((2-1) + (3-2)) + (-1)*(1+2+3) )
  end
end

describe "calculating quality with weights" do
  before do
    @o = OneMinOneMaxObjective1.new
    @o.weights = {:objective_min_distance_between => 2, :objective_max_sum => 3}
  end

  it "uses the weights when calculating quality" do
    i1 = [1,2,3]
    @o.weights = {:objective_min_distance_between => 2, :objective_max_sum => 3}
    q1 = @o.quality_of(i1)
    q1.value.must_equal( 2*((2-1) + (3-2)) + (-3)*(1+2+3) )
    q1.sub_qualities.must_equal [2.0, 6.0]
    q1.candidate.must_equal i1
    q1.objective.must_equal @o
    q1.version.must_equal @o.current_version    

    @o.weights = {:objective_min_distance_between => 5, :objective_max_sum => 30}
    q2 = @o.quality_of(i1)
    q2.value.must_equal( 5*((2-1) + (3-2)) + (-30)*(1+2+3) )
    q2.sub_qualities.must_equal [2.0, 6.0]
  end
end