require 'feldtruby/statistics/distance/dsa_tree'

require 'pp'

describe "FeldtRuby::DSATree" do
  before do
    @t = FeldtRuby::DSATree.new(2)
  end

  it "allows insertion of objects, and the tree is properly built based on distances" do
    @t.insert [0,0]
    @t.root.object.must_equal [0,0]
    @t.root.children.must_equal []

    @t.insert [0,1]
    @t.root.object.must_equal [0,0]
    @t.root.children[0].object.must_equal [0,1]

    @t.insert [1,0]
    @t.root.object.must_equal [0,0]
    @t.root.children[0].object.must_equal [0,1]
    @t.root.children[1].object.must_equal [1,0]

    @t.insert [1,0.1]
    @t.root.children[1].children[0].object.must_equal [1,0.1]

    @t.insert [1,-0.1]
    @t.root.children[1].children[1].object.must_equal [1,-0.1]

    @t.insert [0.1,1]
    @t.root.children[0].children[0].object.must_equal [0.1,1]

    @t.insert [-0.1,1]
    @t.root.children[0].children[1].object.must_equal [-0.1,1]
  end

  it "does not find any points in range when there is only one and it is used as the query object" do
    @t.insert [0,0]
    @t.range_search([0,0], 1.0).must_equal []
  end

  it "finds the other point within range if there are two points and one is used as query object" do
    @t.insert [0,0]
    @t.insert [1,0]

    @t.range_search([0,0], 5.0).must_equal [[1,0]]
    @t.range_search([0,0], 1.0).must_equal [[1,0]]

    @t.range_search([1,0], 5.0).must_equal [[0,0]]
    @t.range_search([1,0], 1.0).must_equal [[0,0]]
  end

  it "does not find a point which is out of range" do
    @t.insert [0,0]
    @t.insert [1,0]
    @t.range_search([0,0], 0.999).must_equal []
  end
end