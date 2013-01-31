require 'feldtruby/array'

module FeldtRuby

class FastMap
  # A PivotNode has two pivot objects, a map from each object to its
  # coordinate on the line for these pivots, a distance function and 
  # a child pointing to the next dimension.
  # It maps a multi-variate object to a k-dimensional coordinate.
  class PivotNode
    attr_writer :map, :child

    def initialize(distance, pivot1, pivot2, map = nil, child = nil)
      @distance, @pivot1, @pivot2, @map, @child = distance, pivot1, pivot2, map, child
      @d_1_2 = distance.calc(pivot1, pivot2)
      @d_1_2_squared, @d_1_2_doubled = @d_1_2 * @d_1_2, 2 * @d_1_2
    end

    # The number of coordinates that will be returned for an object.
    def k; depth; end
    def depth
      @depth ||= 1 + (@child ? @child.depth : 0)
    end

    # Map an object to its coordinate in the dimension represented by this node.
    def fastmap_coordinate(o)
      ( @distance.calc(o, @pivot1) + @d_1_2_squared - @distance.calc(o, @pivot2) ) / @d_1_2_doubled
    end

    def coordinate(o)
      [map_object_to_coordinate(o)] + (@child ? @child.coordinate(o) : [])
    end

    def [](object)
      coordinate(object)
    end

    def map_object_to_coordinate(o)
      @map[o] || fastmap_coordinate(o)
    end
  end

  def initialize(distance, k = 2, choiceDepth = 1)
    @distance, @k, @choice_depth = distance, k, choiceDepth
  end

  def run(objects)
    @objects = objects
    create_map(@k, @distance)
  end

  def create_map(k, distance)
    return nil if k == 0
    o1, o2 = choose_distant_objects(@objects, @distance)
    node = PivotNode.new(distance, o1, o2)
    coordinate_map = {}
    if distance.calc(o1, o2) == 0.0
      @objects.each {|o| coordinate_map[o] = 0.0}
    else
      @objects.each {|o| coordinate_map[o] = node.fastmap_coordinate(o)}
    end
    node.map = coordinate_map
    node.child = create_map k-1, next_distance(distance, o1, o2, coordinate_map)
    node
  end

  def choose_distant_objects(objects, distance)
    o1 = nil
    o2 = objects.sample
    # Not sure if there is any benefit to doing this more than once. Test later.
    @choice_depth.times do
      o1 = find_most_distant_object(objects, o2, distance)
      o2 = find_most_distant_object(objects, o1, distance)
    end
    return o1, o2
  end

  # Find the object in objects that is farthest from o, given a distance function.
  def find_most_distant_object(objects, o, distance)
    objects.sort_by {|oi| distance.calc(oi, o)}.last
  end

  class DistanceFunction
    def initialize(&func)
      @func = func
    end
    def calc(o1, o2)
      @func.call(o1, o2)
    end
  end

  # Create the next distance function from a given distance func.
  def next_distance(distance, o1, o2, coordinates)
    DistanceFunction.new do |oi, oj| 
      Math.sqrt( distance.calc(oi, oj)**2 - (coordinates[oi] - coordinates[oj])**2 )
    end
  end
end

# Recursively map n-dimensional objects (given as an Array) into a k-dimensional
# space while preserving the distances between the objects as well as possible.
def self.fastmap(objects, distance, k = 2)
  FastMap.new(distance, k).run(objects)
end

end