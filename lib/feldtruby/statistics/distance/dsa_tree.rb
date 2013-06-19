require 'feldtruby/statistics/euclidean_distance'

module FeldtRuby

# A DSATree is a tree of nodes with a shared notion of time that can be 
# dynamically built/updated and supports approximate similarity queries. 
# Based on the paper
#   Navarro and Reyes, "Dynamic Spatial Approximation Trees", 2007.
class DSATree

  # A node in a DSATree.
  class Node
    attr_reader :object, :children

    def initialize(object, time = 0, root)
      @object, @time = object, time
      @radius = 0
      @children = []
      @root = root
    end

    # Insert object x into the tree. Returns the node in which the object was 
    # inserted.
    def insert(x)
      da = distance(@object, x)
      @radius = [@radius, da].max
      c = closest_child(x)
      if c.nil? || (da < distance(c.object, x) && @children.length <= @root.max_arity)
        @children << (nx = Node.new(x, @root.advance_time(), @root))
        nx
      else
        c.insert(x)
      end
    end

    # Return all objects within queryRadius from queryObject.
    def range_search(queryObject, queryRadius, timestamp = Float::INFINITY)
      puts "#{@object}, t = #{@time}: range_search(#{queryObject}, #{queryRadius}, #{timestamp})"
      da = distance(@object, queryObject)
      puts "d1(#{@object.inspect}, #{queryObject.inspect}) = #{da}"
      if @time < timestamp && da <= @radius + queryRadius
        result = (da <= queryRadius && da != 0.0) ? [@object] : []
        puts "result 1 = #{result.inspect}"
        dmin = Float::INFINITY
        r2 = 2 * queryRadius
        @children.each_with_index do |b, i|
          db = distance(b.object, queryObject)
          puts "d2(#{b.object.inspect}, #{queryObject.inspect}) = #{db}"
          if db <= dmin + r2
            ts = timestamps_of_children_closer_than(i+1, db - r2, queryObject)
            puts "ts = #{ts.inspect}"
            tprim = ([timestamp] + ts).min
            puts tprim.inspect
            result.concat b.range_search(queryObject, queryRadius, tprim)
            puts "result 2 = #{result.inspect}"
            dmin = db < dmin ? db : dmin
          end
        end
        result
      else
        []
      end
    end

    def timestamps_of_children_closer_than(startIndex, dist, q)
      (startIndex...(@children.length)).inject([]) do |res, j|
        bj = @children[j]
        res << bj.time if distance(bj.object, q) < dist
        res
      end
    end

    def closest_child(x)
      @children.sort_by {|c| distance(c.object, x)}.first
    end

    # The distance function used. Override this to implement other distances, the
    # default is euclidean distance.
    def distance(x, y)
      FeldtRuby.euclidean_distance(x, y)
    end
  end

  attr_reader :current_time, :max_arity, :root

  def initialize(maxArity = 10)
    @current_time = 0
    @max_arity = maxArity
  end

  def advance_time
    @current_time += 1
  end

  def insert(object)
    if @root
      @root.insert object
    else
      @root = Node.new object, advance_time(), self
    end
  end

  def range_search(queryObject, queryRadius)
    return [] unless @root
    @root.range_search queryObject, queryRadius
  end
end

end