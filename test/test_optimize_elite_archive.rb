require 'feldtruby/optimize/elite_archive'

class TwoMinOneMax < FeldtRuby::Optimize::Objective
  def objective_min_1(x)
    x.sum
  end

  def objective_min_2(x)
    x.max
  end

  def objective_max_1(x)
    x.min
  end
end

describe "EliteArchive" do
  before do
    @o = TwoMinOneMax.new(FeldtRuby::Optimize::Objective::WeightedSumAggregator.new)
    @a = FeldtRuby::Optimize::EliteArchive.new(@o, {
    :NumTopPerGoal => 2,
    :NumTopAggregate => 3})
  end

  it 'is adapted to an objective when created' do
    @a.objective.must_equal @o
    @a.top_per_goal.length.must_equal @o.num_goals
  end

  it 'properly handles additions' do
    i1 = [1,2,3]
    @a.add i1 # [6, 3, 1] => 8
    @a.best.length.must_equal 1
    @a.top_per_goal[0].length.must_equal 1
    @a.top_per_goal[1].length.must_equal 1
    @a.top_per_goal[2].length.must_equal 1

    i2 = [1,2,4]
    @a.add i2 # [7, 4, 1] => 10
    @a.best.length.must_equal 2
    @a.top_per_goal[0].length.must_equal 2
    @a.top_per_goal[1].length.must_equal 2
    @a.top_per_goal[2].length.must_equal 2
    @a.top_per_goal[0][0].must_equal i1
    @a.top_per_goal[0][1].must_equal i2
    @a.top_per_goal[1][0].must_equal i1
    @a.top_per_goal[1][1].must_equal i2

    i3 = [1,2,0] # [3, 2, 0] => 5 
    @a.add i3

    @a.best.length.must_equal 3
    @a.top_per_goal[0].length.must_equal 2
    @a.top_per_goal[1].length.must_equal 2
    @a.top_per_goal[2].length.must_equal 2

    @a.best[0].must_equal i3
    @a.best[1].must_equal i1
    @a.best[2].must_equal i2

    @a.top_per_goal[0][0].must_equal i3
    @a.top_per_goal[0][1].must_equal i1

    @a.top_per_goal[1][0].must_equal i3
    @a.top_per_goal[1][1].must_equal i1

    @a.top_per_goal[2][0].must_equal i1
    @a.top_per_goal[2][1].must_equal i2

    i4 = [5,5,10] # [20, 10, 5] => 25
    @a.add i4

    @a.best.length.must_equal 3
    @a.top_per_goal[0].length.must_equal 2
    @a.top_per_goal[1].length.must_equal 2
    @a.top_per_goal[2].length.must_equal 2

    @a.best[0].must_equal i3
    @a.best[1].must_equal i1
    @a.best[2].must_equal i2

    @a.top_per_goal[2][0].must_equal i4
    @a.top_per_goal[2][1].must_equal i1
  end
end