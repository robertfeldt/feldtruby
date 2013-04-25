require 'feldtruby/statistics/distance/distance_matrix'
include FeldtRuby::Statistics

def rand_string(length)
  chars = ('a'..'z').to_a
  num_chars = chars.length
  Array.new(length).map {chars[rand(num_chars)]}.join
end

describe "DistanceMatrix" do
  before do
    @dm0 = FeldtRuby::Statistics::DistanceMatrix.new
    @dm2 = FeldtRuby::Statistics::DistanceMatrix.new({:a3 => "aaa", :a2b => "aab"})
    @dm3 = FeldtRuby::Statistics::DistanceMatrix.new({:a3 => "aaa", :a2b => "aab", :a1b2 => "abb"})
    a1 = rand_string(100)
    a2 = rand_string(100)
    b1 = rand_string(100)
    b2 = rand_string(100)
    @dm5 = FeldtRuby::Statistics::DistanceMatrix.new({
      :a1a2 => (a1+a2), :a2a1 => (a2+a1), 
      :b1b2 => (b1+b2), :b2b1 => (b2+b1),
      :a1a2b1 => (a1+a2+b1)})
  end

  it "can be created empty" do
    @dm0.num_nodes.must_equal 0
  end

  it "can be created with one node" do
    dm1 = FeldtRuby::Statistics::DistanceMatrix.new({:a3 => "aaa"})
    dm1.num_nodes.must_equal 1
  end

  it "can be created with two nodes" do
    @dm2.num_nodes.must_equal 2
  end

  it "can be created with three nodes" do
    @dm3.num_nodes.must_equal 3
  end

  it "can return the distance between pairs of objects in the matrix" do
    d1 = @dm3.distance(:a3, :a2b)
    d1.must_be_instance_of Float

    d2 = @dm3.distance(:a3, :a1b2)
    d2.must_be_instance_of Float

    d3 = @dm3.distance(:a2b, :a1b2)
    d3.must_be_instance_of Float

    d1.must_be :<, d2
  end

  it "can update with new objects after initialization" do
    @dm3.add_node :a4, "aaaa"
    @dm3.num_nodes.must_equal 4
  end

  it "can dump to libqsearch text format" do
    s = @dm3.to_libqsearch_text_distance_matrix
    lines = s.split("\n")
    lines.length.must_equal 3
    lines.each do |line|
      vals = line.split(" ")
      @dm3.names.include?(vals[0])
      vals[1..-1].each do |v|
        v.must_match /\d+,\d+/
      end
    end
    @dm5.to_libqsearch_text_distance_matrix.split("\n").length.must_equal 5
  end
end

#require 'pp'
#require 'json'

describe "FileDistanceMatrix" do
  it "can create a tree.ps file using neato if libqsearch (maketree) and neato (graphviz) are both installed" do
    #if `maketree -v` =~ /\d+\.\d+.\d+/ && `neato -V` =~ /neato - graphviz version \d+\.\d+.\d+/
      fdm = FeldtRuby::Statistics::FileDistanceMatrix.from_files_in_dir "lib/feldtruby/statistics"
      #puts fdm.to_d3_force_layout.to_json
      output_file = "tree.ps"
      fdm.to_quartet_tree_in_postscript_file output_file
      File.exist?(output_file).must_equal true
      File.delete output_file
    #end
  end
end