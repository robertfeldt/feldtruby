require 'feldtruby/optimize/adaptive_partitioning_tree_archive'

# Dummy objective to test with.
class DummyObjective2 < FeldtRuby::Optimize::Objective
  def goal_min_sum(candidate)
    candidate.sum
  end
  def goal_min_min(candidate)
    candidate.min
  end
end

FOO = FeldtRuby::Optimize::Objective

describe 'AdaptivePartioningTreeArchive' do
  before do
    @o = DummyObjective2.new FOO::MeanWeigthedGlobalRatios.new, FOO::ParetoNonDominanceComparator.new
    @apta = FeldtRuby::Optimize::AdaptivePartioningTreeArchive.new @o
  end

  it "has an inactive root node from the start, i.e. when it is empty" do
    @apta.root.type.must_equal :inactive
  end

  it "has a default value range when empty" do
    @apta.root.value_range_min.length.must_equal 2
    @apta.root.value_range_min.must_equal [-10.0, -10.0]
    @apta.root.value_range_max.must_equal [10.0, 10.0]
  end

  it "becomes a leaf node when a solution is added" do
    @apta.add_solution [1,2]
    @apta.root.type.must_equal :leaf
    @apta.root.num_solutions.must_equal 1
  end

  it "does not add solutions that is already in the archive" do
    20.times do
      @apta.add_solution [1,2]
    end
    @apta.root.type.must_equal :leaf
    @apta.root.num_solutions.must_equal 1
  end

  it "adds only solutions that are non-dominated" do
    r1 = @apta.add_solution [1,2]      # 1. objectives: [3, 1]
    r1.must_equal true

    r2 = @apta.add_solution [1,1.9]    # 2. objectives: [2.9, 1], dominates 1
    r2.must_equal true

    r3 = @apta.add_solution [1,1.8]    # 3. objectives: [2.8, 1], dominates 1 and 2
    r3.must_equal true

    r4 = @apta.add_solution [0.9,2.1]  # 4. objectives: [3, 0.9], dominates 1 and 2 but not 3
    r4.must_equal true

    @apta.add_solution([1,2]).must_equal false  # 1. objectives: [3, 1], already dominated
    @apta.add_solution([1,1.9]).must_equal false  # 2. objectives: [2.9, 1], already dominated
    @apta.add_solution([1,1.8]).must_equal false  # already in archive
    @apta.add_solution([0.9,2.1]).must_equal false  # already in archive

    @apta.root.type.must_equal :leaf
    @apta.root.num_solutions.must_equal 2
  end

end