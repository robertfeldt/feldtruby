require 'feldtruby/statistics/distance/string_distance'

module FeldtRuby::Statistics

# A distance matrix calculates and saves all the pair-wise distances between
# objects. Objects are given initially as a map from the node name to the node
# object (a string). Links are given as a map from a pair of node names to the weight.
class DistanceMatrix

  def initialize(nodes = {}, distance = FeldtRuby::Statistics::NCD.new)
    # First create an empty hash of the nodes, then update it with the supplied
    # nodes below.
    @nodes = {}

    # Wrap the distance object so that distance calculations are cached. This
    # will be beneficial since we know we will be calling with the same
    # individual objects again and again (since they are in many pairs of the
    # matrix).    
    @distance_func = FeldtRuby::Statistics::CachingStringDistance.new(distance)

    # The distances are saved as a hash from the (src) node names to a hash
    # mapping the (dest) node name to the distance (saved as a float).
    @distances = Hash.new {|h,k| h[k] = Hash.new}

    nodes.each {|name, object| add_node(name, object)}
  end

  def num_nodes
    @nodes.length
  end

  # Add a named object.
  def add_node name, object
    @nodes[name] = object
  end

  def distance(name1, name2)
    d = @distances[name1][name2] || @distances[name2][name1]
    return d if d
    @distances[name1][name2] = @distance_func.distance(@nodes[name1], @nodes[name2])
  end

  # Deprecated.
  def create_name_from_object object
    name = object.to_s.gsub(/\s*/, "")[0,20]
    while @nodes.keys.include?(name)
      name += rand(10)
    end
    name
  end

end

end