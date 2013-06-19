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

def euclidean_distance(o1, o2)
  (@euclidean_distance ||= EuclideanDistance.new).calc(o1, o2)
end

def self.euclidean_distance(o1, o2)
  (@euclidean_distance ||= EuclideanDistance.new).calc(o1, o2)
end

end