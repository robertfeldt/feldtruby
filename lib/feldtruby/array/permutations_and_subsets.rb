class Array
  def all_pairs

    return [] if length < 2

    x, *rest = self

    rest.map {|e| [x, e]} + rest.all_pairs

  end

  # Create all combinations of values from an array of sub-arrays, with
  # each combination picking one value from each sub-array.
  #
  # Examples: 
  #  [[1,2], [3]].all_combinations_one_from_each => [[1,3], [2,3]]
  #
  #  [[1,2], [3, 7]].all_combinations_one_from_each => [[1,3], [2,3], [1,7], [2,7]]
  def all_combinations_one_from_each
    return [] if length == 0

    return self.first.map {|v| [v]} if length == 1

    self[1..-1].all_combinations_one_from_each.map do |c|
      self.first.map {|v| [v] + c}
    end.flatten(1)
  end
end