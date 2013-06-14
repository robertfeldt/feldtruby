require 'feldtruby'
require 'feldtruby/statistics/distance/string_distance'
require 'feldtruby/command_runner'
require 'stringio'

module FeldtRuby::Statistics

# A distance matrix calculates and saves all the pair-wise distances between
# objects. Objects are given initially as a map from the node name to the node
# object (a string). Links are given as a map from a pair of node names to the weight.
class DistanceMatrix

  def initialize(nodes = {}, distanceFunc = FeldtRuby::Statistics::NCD.new)
    # First create an empty hash of the nodes, then update it with the supplied
    # nodes below.
    @nodes = {}

    # Wrap the distance object so that distance calculations are cached. This
    # will be beneficial since we know we will be calling with the same
    # individual objects again and again (since they are in many pairs of the
    # matrix).    
    @distance_func = FeldtRuby::Statistics::CachingStringDistance.new(distanceFunc)

    # The distances are saved as a hash from the (src) node names to a hash
    # mapping the (dest) node name to the distance (saved as a float).
    @distances = Hash.new {|h,k| h[k] = Hash.new}

    nodes.each {|name, object| add_node(name, object)}
  end

  def num_nodes
    @nodes.length
  end

  def names
    @nodes.keys
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

  # Yield each distance sending the names and the distance along to the block.
  def each_distance
    ns = names
    max_index = ns.length - 1
    0.upto(max_index-1) do |i|
      name1 = ns[i]
      (i+1).upto(max_index) do |j|
        name2 = ns[j]
        yield name1, name2, distance(name1, name2) 
      end
    end
  end

  # Output a distance matrix in the text format accepted by the libqsearch
  # library by Rudi Cilibrasi.
  def to_libqsearch_text_distance_matrix
    sio = StringIO.new
    ns = names
    ns.each do |src_name|
      sio.print src_name
      ns.each do |dest_name|
        next if dest_name == src_name
        d = distance(src_name, dest_name)
        sio.print( " " + d.to_s.gsub(".", ",") )
      end
      sio.print "\n"
    end
    sio.string
  end

  # Build an optimal quartet tree from the distances in this matrix, then
  # dump it to a postscript file. Assumes that maketree from libqsearch
  # and neato from graphviz is installed.
  def to_quartet_tree_in_postscript_file(postscriptFilename)
    FeldtRuby::CommandRunner.new do |c|

      # Run make tree command on text dist matrix. Creates result in treefile.dot.
      c.run "maketree", c.use_as_file_arg(to_libqsearch_text_distance_matrix)

      # Ensure the postscript file is not deleted
      c.keep_file postscriptFilename

      # Run neato command on treefile.dot file
      c.run "neato -Tps -Gsize=7,7 -o", postscriptFilename, "treefile.dot" 

    end.start
  end

  # Create a D3.js force layout format json hash which can be later dumped
  # to json and used as input in D3.
  def to_d3_force_layout
    index = -1
    nodes = names.map {|n| {"name" => n, "group" => 1, "index" => (index+=1)}}
    links = []
    nodes.each do |srcnode|
      nodes.each do |destnode|
        next if srcnode == destnode
        d = distance(srcnode["name"], destnode["name"])
        links << {"source" => srcnode["index"], "target" => destnode["index"], 
          "value" => d}
      end
    end
    {"nodes" => nodes, "links" => links}
  end

end

# Create a distance matrix between files identified by their file paths.
class FileDistanceMatrix < DistanceMatrix
  def initialize(filepaths = [], distanceFunc = FeldtRuby::Statistics::NCD.new)
    super({}, distanceFunc)
    filepaths.each {|fp| add_file(fp)}
  end

  def add_file filePath
    File.open(filePath, "r") do |fh|
      # We can't use the file path since maketree cannot handle slashes in the object names.
      # Lets strip of and only use the filename.
      add_node File.basename(filePath), fh.read
    end
  end

  private :add_node

  def self.from_files_in_dir(dir, distanceFunc = FeldtRuby::Statistics::NCD.new)
    files = Dir[dir + "/*"].select {|fp| File.file?(fp)}
    new files, distanceFunc
  end
end

end