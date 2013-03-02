require 'feldtruby/statistics/array_archive'

describe "MinMaxAveragePositionArchive" do
  before do
    @a = FeldtRuby::MinMaxAveragePerPositionArchive.new
  end

  it "updates the counts as we add arrays" do
    @a.count.must_equal 0
    @a.update([1,2,3])
    @a.count.must_equal 1
    @a.update([4,5,6])
    @a.count.must_equal 2
    @a.update([1,2,3])
    @a.count.must_equal 3
  end

  it "correctly updates the min values" do
    @a.min_for_position(0).must_equal nil

    @a.update([1,2,3])
    @a.min_for_position(0).must_equal 1
    @a.min_for_position(1).must_equal 2
    @a.min_for_position(2).must_equal 3
    @a.mins.must_equal [1,2,3]

    @a.update([1,5,-2])
    @a.mins.must_equal [1,2,-2]
    @a.min_for_position(0).must_equal 1
    @a.min_for_position(1).must_equal 2
    @a.min_for_position(2).must_equal -2
  end

  it "correctly updates the max values" do
    @a.max_for_position(0).must_equal nil

    @a.update([1,2,3])
    @a.max_for_position(0).must_equal 1
    @a.max_for_position(1).must_equal 2
    @a.max_for_position(2).must_equal 3
    @a.maxs.must_equal [1,2,3]

    @a.update([1,5,-2])
    @a.maxs.must_equal [1,5,3]
    @a.max_for_position(0).must_equal 1
    @a.max_for_position(1).must_equal 5
    @a.max_for_position(2).must_equal 3
  end

  it "correctly updates the mean values" do
    @a.mean_for_position(0).must_equal nil

    @a.update([1,2,3])
    @a.mean_for_position(0).must_equal 1
    @a.mean_for_position(1).must_equal 2
    @a.mean_for_position(2).must_equal 3
    @a.means.must_equal [1,2,3]

    @a.update([1,5,-2])
    @a.means.must_equal [1, 3.5, 0.5]
    @a.mean_for_position(0).must_equal 1
    @a.mean_for_position(1).must_equal 3.5
    @a.mean_for_position(2).must_equal 0.5
  end
end