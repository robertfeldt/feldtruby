module FeldtRuby

class EuclideanDistance
  def calc(o1, o2)
    sum = 0.0
    o1.length.times do |i|
      d = (o1[i] - o2[i])
      sum += (d*d)
    end
    Math.sqrt(sum)
  end
end

end