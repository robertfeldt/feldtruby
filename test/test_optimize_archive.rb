require 'feldtruby/optimize/archive'

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

class DivObj2 < FeldtRuby::Optimize::EuclideanDistanceToBest
  # Diversity goal 2: AMGA2 crowding distance to nearest neighbours in fitness 
  # space. Phenotype diversity.
  def goal_max_crowding_distance_to_nearest_neighbours(candidate)
    # FIX: Below we need to handle the case where the candidate is an extremal
    # solution and thus only has one nearest neighbour. Give it very high diversity?
    nn1, nn2 = archive.find_nearest_neighbours_in_fitness(candidate)
    sqv1 = archive.objective.quality_of(nn1).sub_qualitites
    sqv2 = archive.objective.quality_of(nn2).sub_qualitites
    sqvme = archive.objective.quality_of(candidate).sub_qualitites
    ((sqv1 - sqvme) * (sqv2 - sqvme)).abs.sum
  end
end

require 'pp'

describe "Archive" do
  before do
    @o = TwoMinOneMax.new(FeldtRuby::Optimize::Objective::WeightedSumAggregator.new)
    @do = FeldtRuby::Optimize::EuclideanDistanceToBest.new(FeldtRuby::Optimize::Objective::WeightedSumAggregator.new)
    @a = FeldtRuby::Optimize::Archive.new(@o, @do, {
    :NumTopPerGoal => 2,
    :NumTopAggregate => 3,
    :NumTopDiversityAggregate => 2})
  end

  it 'can dump itself to json' do
    @a.add [1,2,3]
    js = @a.to_json
    js.must_be_kind_of String
    hash = JSON.parse js
    hash.must_be_kind_of Hash
    hash['json_class'].must_equal "FeldtRuby::Optimize::Archive"
    hash['data'].keys.sort.must_equal ["generalists", "specialists", "weirdos"].sort
    tl = hash['data']['generalists']['data']['top_list']
    tl.must_be_kind_of Array
    tl.length.must_equal 1
  end

  it 'is adapted to objectives when created' do
    @a.objective.must_equal @o
    @a.diversity_objective.must_equal @do
    @a.specialists.length.must_equal @o.num_goals
    @a.generalists.must_be_kind_of FeldtRuby::Optimize::Archive::GlobalTopList
    @a.weirdos.must_be_kind_of FeldtRuby::Optimize::Archive::GlobalTopList
  end

  it 'does not yet have a best value when created' do
    @a.best.must_equal nil
  end

  it 'properly handles additions' do
    i1 = [1,2,3]
    @a.add i1 # [6, 3, 1] => 10

    @a.best.must_equal i1

    @a.generalists.length.must_equal 1
    @a.generalists[0].must_equal i1

    @a.specialists[0].length.must_equal 1
    @a.specialists[1].length.must_equal 1
    @a.specialists[2].length.must_equal 1

    @a.weirdos.length.must_equal 0

    i2 = [1,2,4]
    @a.add i2 # [7, 4, 1] => 12

    @a.best.must_equal i1

    @a.generalists.length.must_equal 2
    @a.generalists[0].must_equal i1
    @a.generalists[1].must_equal i2

    @a.specialists[0].length.must_equal 2
    @a.specialists[1].length.must_equal 2
    @a.specialists[2].length.must_equal 2
    @a.specialists[0][0].must_equal i1
    @a.specialists[0][1].must_equal i2
    @a.specialists[1][0].must_equal i1
    @a.specialists[1][1].must_equal i2

    @a.weirdos.length.must_equal 0

    i3 = [1,2,0] # [3, 2, 0] => 5
    @a.add i3

    @a.best.must_equal i3
    @a.generalists.length.must_equal 3
    @a.generalists[0].must_equal i3
    @a.generalists[1].must_equal i1
    @a.generalists[2].must_equal i2

    @a.specialists[0].length.must_equal 2
    @a.specialists[1].length.must_equal 2
    @a.specialists[2].length.must_equal 2
    @a.specialists[0][0].must_equal i3
    @a.specialists[0][1].must_equal i1
    @a.specialists[1][0].must_equal i3
    @a.specialists[1][1].must_equal i1

    @a.weirdos.length.must_equal 0

    # Introduce a new baddest one
    i4 = [5,5,10] # [20, 10, 5] => 35
    @a.add i4

    @a.best.must_equal i3
    @a.generalists.length.must_equal 3
    @a.generalists[0].must_equal i3
    @a.generalists[1].must_equal i1
    @a.generalists[2].must_equal i2

    @a.specialists[0].length.must_equal 2
    @a.specialists[1].length.must_equal 2
    @a.specialists[2].length.must_equal 2
    @a.specialists[0][0].must_equal i3
    @a.specialists[0][1].must_equal i1
    @a.specialists[1][0].must_equal i3
    @a.specialists[1][1].must_equal i1

    @a.weirdos.length.must_equal 0

    # Introduce a new 2nd best
    i5 = [3,0,1] # [4, 3, 0] => 7
    @a.add i5

    @a.best.must_equal i3
    @a.generalists.length.must_equal 3
    @a.generalists[0].must_equal i3
    @a.generalists[1].must_equal i5
    @a.generalists[2].must_equal i1

    @a.specialists[0].length.must_equal 2
    @a.specialists[1].length.must_equal 2
    @a.specialists[2].length.must_equal 2
    @a.specialists[0][0].must_equal i3
    @a.specialists[0][1].must_equal i5
    @a.specialists[1][0].must_equal i3
    @a.specialists[1][1].must_equal i1

    @a.weirdos.length.must_equal 0

    # Introduce 2 new that is close to best and goes into top list but also into
    # weirdos.
    i6 = [1.05,2.05,0] # [3.1, 2.05, 0] => 5.15
    @a.add i6

    i7 = [1.01,2.00,0.10] # [3.11, 2.00, 0.1] => 5.01
    @a.add i7

    @a.best.must_equal i3
    @a.generalists.length.must_equal 3
    @a.generalists[0].must_equal i3
    @a.generalists[1].must_equal i7
    @a.generalists[2].must_equal i6

    @a.specialists[0].length.must_equal 2
    @a.specialists[1].length.must_equal 2
    @a.specialists[2].length.must_equal 2
    @a.specialists[0][0].must_equal i3
    @a.specialists[0][1].must_equal i6
    @a.specialists[1][0].must_equal i3
    @a.specialists[1][1].must_equal i7

    @a.weirdos.length.must_equal 2
    @a.weirdos[0].must_equal i7
    @a.weirdos[1].must_equal i6

    # Introduce one weird which is not good enough to go into the generalists
    # or specialists but goes on top of weirdos.
    i8 = [1.03, 2.10, 0.1] # [3.23, 2.10, 0.1] => 5.23
    @a.good_enough_quality_to_be_interesting?(i8).must_equal true
    @a.add i8

    @a.best.must_equal i3
    @a.generalists.length.must_equal 3
    @a.generalists[0].must_equal i3
    @a.generalists[1].must_equal i7
    @a.generalists[2].must_equal i6

    @a.specialists[0].length.must_equal 2
    @a.specialists[1].length.must_equal 2
    @a.specialists[2].length.must_equal 2
    @a.specialists[0][0].must_equal i3
    @a.specialists[0][1].must_equal i6
    @a.specialists[1][0].must_equal i3
    @a.specialists[1][1].must_equal i7

    @a.weirdos.length.must_equal 2
    @a.weirdos[0].must_equal i8
    @a.weirdos[1].must_equal i7

    # Less weird than i8 but still goes into weirdos.
    i9 = [1.04, 2.08, 0.05] # [3.17, 2.08, 0.05] => 5.20
    @a.add i9

    @a.best.must_equal i3
    @a.generalists.length.must_equal 3
    @a.generalists[0].must_equal i3
    @a.generalists[1].must_equal i7
    @a.generalists[2].must_equal i6

    @a.specialists[0].length.must_equal 2
    @a.specialists[1].length.must_equal 2
    @a.specialists[2].length.must_equal 2
    @a.specialists[0][0].must_equal i3
    @a.specialists[0][1].must_equal i6
    @a.specialists[1][0].must_equal i3
    @a.specialists[1][1].must_equal i7

    @a.weirdos.length.must_equal 2
    @a.weirdos[0].must_equal i8
    @a.weirdos[1].must_equal i9
  end
end