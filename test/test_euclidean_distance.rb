require 'feldtruby/statistics/euclidean_distance'
include FeldtRuby

describe "Euclidean distance" do
  it "can be calculated on float vectors of length 1" do
    euclidean_distance([1.0], [1.0]).must_equal 0.0
  end

  it "can be calculated on float vectors of length 2" do
    euclidean_distance([2.0, -1.0], [-2.0, 2.0]).must_equal 5.0
  end

  it "can be calculated on float vectors of length 3" do
    euclidean_distance([1.0,2.0,3.0], [4.0,5.0,6.0]).must_be_close_to 5.196152
  end

  it "can be calculated on int vectors of length 1" do
    euclidean_distance([1], [1]).must_equal 0.0
  end

  it "can be calculated on int vectors of length 2" do
    euclidean_distance([2, -1], [-2, 2]).must_equal 5.0
  end

  it "can be calculated on int vectors of length 3" do
    euclidean_distance([1,2,3], [4,5,6]).must_be_close_to 5.196152
  end
end