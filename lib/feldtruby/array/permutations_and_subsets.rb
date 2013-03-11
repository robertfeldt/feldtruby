class Array
  def all_pairs

    return [] if length < 2

    x, *rest = self

    rest.map {|e| [x, e]} + rest.all_pairs

  end
end