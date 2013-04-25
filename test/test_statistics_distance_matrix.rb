require 'feldtruby/statistics/distance/distance_matrix'
include FeldtRuby::Statistics

describe "DistanceMatrix" do
  before do
    @dm0 = FeldtRuby::Statistics::DistanceMatrix.new
    @dm2 = FeldtRuby::Statistics::DistanceMatrix.new({:a3 => "aaa", :a2b => "aab"})
    @dm3 = FeldtRuby::Statistics::DistanceMatrix.new({:a3 => "aaa", :a2b => "aab", :a1b2 => "abb"})
  end

  it "can be created empty" do
    @dm0.num_nodes.must_equal 0
  end

  it "can be created with one node" do
    dm1 = FeldtRuby::Statistics::DistanceMatrix.new({:a3 => "aaa"})
    dm1.num_nodes.must_equal 1
  end

  it "can be created with two nodes" do
    @dm2.num_nodes.must_equal 2
  end

  it "can return the distance between pairs of objects in the matrix" do
    d1 = @dm3.distance(:a3, :a2b)
    d1.must_be_instance_of Float

    d2 = @dm3.distance(:a3, :a1b2)
    d2.must_be_instance_of Float

    d3 = @dm3.distance(:a2b, :a1b2)
    d3.must_be_instance_of Float

    d1.must_be :<, d2
  end

  it "can update with new objects after initialization" do
    @dm3.add_node :a4, "aaaa"
    @dm3.num_nodes.must_equal 4
  end
end