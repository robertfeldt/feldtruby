require 'feldtruby/statistics/euclidean_distance'

module FeldtRuby

class Distance
  def calc(o1, o2)
    raise NotImplementedError
  end
end

module CompositableDistance
  def initialize(metric = EuclideanDistance.new)
    @sub_metric = metric
  end
end  

# Functions specific to distances defined on sets of individual objects
module SetDistance
  def pairwise_distances(set1, set2, metric)
    set1.map {|a| set2.map {|b| metric.calc(a,b)}}.flatten
  end
end  

# Metric is a Distance with particular properties. They need to be ensured
# in sub-classes so not defined here though.
class Metric < Distance
end

# A CompositeDistance takes another metric as input and calculates a new 
# distance based on it.
class CompositeMetric < Metric
  include CompositableDistance
end

end