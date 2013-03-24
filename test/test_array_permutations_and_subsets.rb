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

describe 'all combinations of elements from sub-arrays' do
  it 'returns an empty array if no sub-arrays given' do
    [].all_combinations_one_from_each.must_equal []
  end

  it 'can handle the case with only one sub-array' do
    [[1]].all_combinations_one_from_each.must_equal [[1]]
    [[1, 2]].all_combinations_one_from_each.must_equal [[1], [2]]
  end

  it 'can handle a simple, basic example' do
    [[1,2], [3]].all_combinations_one_from_each.must_equal [[1,3], [2,3]]
  end

  it 'can handle the case of two sub-arrays of two elements each' do
    [[1,2], [3,7]].all_combinations_one_from_each.must_equal [[1,3], [2,3], [1,7], [2,7]]
  end

  it 'can handle the case of two sub-arrays of two and three elements, respectively' do
    [[1,2,3], [4,5]].all_combinations_one_from_each.must_equal [[1,4], [2,4], [3,4], [1,5], [2,5], [3,5]]
  end
end