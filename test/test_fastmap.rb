require 'feldtruby/statistics/fastmap'
require 'feldtruby/statistics/euclidean_distance'

describe "Fastmap" do
  it "works for simple data, and different values of k" do
    d = [
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [2, 2, 2, 2],
      [3, 3, 3, 3]
    ]
    1.upto(d.first.length-1) do |k|
      m = FeldtRuby.fastmap(d, FeldtRuby::EuclideanDistance.new, k)
      m.depth.must_equal k
      d.each do |datum|
        c = m[datum]
        c.length.must_equal k
        c.must_equal m[datum]
      end
    end
  end
end