require 'feldtruby/optimize/sub_qualities_comparators'

describe "EpsilonNonDominance with epsilon=0.0 i.e. normal non-dominance" do
  before do
    @c = FeldtRuby::Optimize::EpsilonNonDominance.new(1, 0.0)
  end

  it "correctly calculates dominance for single-objective examples" do
    @c.compare_sub_qualitites([1], [1]).must_equal 0

    @c.first_dominates?([1], [1]).must_equal false
    @c.second_dominates?([1], [1]).must_equal false

    @c.compare_sub_qualitites([1], [2]).must_equal -1
    @c.compare_sub_qualitites([2], [1]).must_equal 1

    @c.compare_sub_qualitites([-1], [1]).must_equal -1
    @c.compare_sub_qualitites([1], [-1]).must_equal 1

    @c.compare_sub_qualitites([-10], [0]).must_equal -1
    @c.compare_sub_qualitites([0], [-10]).must_equal 1
  end

  it "correctly calculates dominance for two-objective examples" do
    @c.compare_sub_qualitites([2, 1], [2, 1]).must_equal 0

    @c.compare_sub_qualitites([1, 2], [1, 3]).must_equal -1
    @c.compare_sub_qualitites([1, 3], [1, 2]).must_equal 1

    @c.compare_sub_qualitites([2, -1], [3, -1]).must_equal -1
    @c.compare_sub_qualitites([3, -1], [2, -1]).must_equal 1

    @c.compare_sub_qualitites([1, 2], [2, 1]).must_equal 0
  end

  it "correctly calculates dominance for three-objective examples" do
    @c.compare_sub_qualitites([1, 2, 4], [1, 2, 4]).must_equal 0

    @c.compare_sub_qualitites([1, 2, 4], [1, 3, 4]).must_equal -1
    @c.compare_sub_qualitites([1, 3, 4], [1, 2, 4]).must_equal 1

    @c.compare_sub_qualitites([1, 2, 3], [1, 3, 4]).must_equal -1
    @c.compare_sub_qualitites([1, 3, 4], [1, 2, 3]).must_equal 1
  end

  it "never shows dominance when comparing the same objects" do
    100.times do
      candidate = Array.new(1 + rand(20)).map {rand(1e3)}
      @c.compare_sub_qualitites(candidate, candidate).must_equal 0
    end
  end

  it "always shows dominance when comparing objects where left is better in a single sub-objective" do
    100.times do
      candidate1 = Array.new(1 + rand(20)).map {rand(1e3)}
      candidate2 = candidate1.clone
      candidate2[rand(candidate2.length)] += 1
      @c.compare_sub_qualitites(candidate1, candidate2).must_equal -1
    end
  end

  it "always shows dominance when comparing objects where right is better in a single sub-objective" do
    100.times do
      candidate1 = Array.new(1 + rand(20)).map {rand(1e3)}
      candidate2 = candidate1.clone
      candidate2[rand(candidate2.length)] -= 1
      @c.compare_sub_qualitites(candidate1, candidate2).must_equal 1
    end
  end
end

describe "EpsilonNonDominance with epsilon=1.0" do
  before do
    @c = FeldtRuby::Optimize::EpsilonNonDominance.new(1, 1.0)
  end

  it "correctly calculates dominance for single-objective examples" do
    @c.compare_sub_qualitites([1], [1]).must_equal 0

    @c.compare_sub_qualitites([1], [2]).must_equal 0
    @c.compare_sub_qualitites([2], [1]).must_equal 0

    @c.compare_sub_qualitites([1], [2.01]).must_equal -1
    @c.compare_sub_qualitites([2.01], [1]).must_equal 1

    @c.compare_sub_qualitites([-1], [1]).must_equal -1
    @c.compare_sub_qualitites([1], [-1]).must_equal 1

    @c.compare_sub_qualitites([-10], [0]).must_equal -1
    @c.compare_sub_qualitites([0], [-10]).must_equal 1
  end

  it "correctly calculates dominance for two-objective examples" do
    @c.compare_sub_qualitites([2, 1], [2, 1]).must_equal 0

    @c.compare_sub_qualitites([1, 2], [1, 3]).must_equal 0
    @c.compare_sub_qualitites([1, 3], [1, 2]).must_equal 0

    @c.compare_sub_qualitites([1, 1.9], [1, 3]).must_equal -1
    @c.compare_sub_qualitites([1, 3.1], [1, 2]).must_equal 1

    @c.compare_sub_qualitites([2, -1], [4, -1]).must_equal -1
    @c.compare_sub_qualitites([4, -1], [2, -1]).must_equal 1

    @c.compare_sub_qualitites([1, 2], [2, 1]).must_equal 0

    @c.compare_sub_qualitites([1, 3], [2, 1]).must_equal 1
  end
end