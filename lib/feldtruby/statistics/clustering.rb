require 'feldtruby/statistics/distance'
require 'feldtruby/array/basic_stats'

module FeldtRuby

class ClusterLinkageMetric < CompositeMetric
  include SetDistance
end

# Average linkage metric between clusters.
class AverageLinkageMetric < ClusterLinkageMetric
  def calc(cluster1, cluster2)
    pairwise_distances(cluster1, cluster2, @sub_metric).sum.to_f / (cluster1.length * cluster2.length)
  end
end

# Single linkage metric between clusters - distance between nearest members.
class SingleLinkageMetric < ClusterLinkageMetric
  def calc(cluster1, cluster2)
    pairwise_distances(cluster1, cluster2, @sub_metric).min
  end
end

# Complete linkage metric between clusters - distance between furthest members.
class CompleteLinkageMetric < ClusterLinkageMetric
  def calc(cluster1, cluster2)
    pairwise_distances(cluster1, cluster2, @sub_metric).max
  end
end

end