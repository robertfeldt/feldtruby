require 'feldtruby/array/permutations_and_subsets'

describe "all pairs of elements from an array" do

  it "cannot return any pairs if there are fewer than 2 elements" do

    [].all_pairs.must_equal []
    [1].all_pairs.must_equal []
    [:a].all_pairs.must_equal []

  end

  it "returns the only pair if 2 elements" do

    [1, 2].all_pairs.must_equal [[1, 2]]
    [1, "a"].all_pairs.must_equal [[1, "a"]]

  end

  it "returns the right pairs when 3 elements" do

    [1, 2, 3].all_pairs.sort.must_equal [[1, 2], [1, 3], [2, 3]].sort

  end

  def invariant_all_original_elements_are_at_least_in_one_pair(ary)

    ary.all_pairs.flatten.uniq.sort.must_equal ary.uniq.sort

  end

  repeatedly_it "returns the right number of pairs when > 3 elements" do

    ary = Array.new(4 + rand(10)).map {rand(1000)}

    invariant_all_original_elements_are_at_least_in_one_pair ary

    num_pairs = ary.all_pairs
    n = ary.length

  end

end