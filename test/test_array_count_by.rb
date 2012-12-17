require 'minitest/spec'
require 'feldtruby/array/count_by'

describe "Array#count_by" do
  it "counts right" do
    counts = ["a", "ab", "b", "abfd", "e", "gf"].count_by {|e| e.length}
    counts.must_be_instance_of Hash
    counts.keys.sort.must_equal [1, 2, 4]
    counts[1].must_equal 3
    counts[2].must_equal 2
    counts[4].must_equal 1
  end
end