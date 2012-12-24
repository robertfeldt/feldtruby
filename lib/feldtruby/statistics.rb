require 'rinruby'
require 'json'

require 'feldtruby/array'
require 'feldtruby/array/basic_stats'

module FeldtRuby

# RCommunicator uses RinRuby to communicate with an instance of R.
# We extend the basic RinRuby by using json to tunnel back and forth.
class RCommunicator
  def initialize
    # Will stay open until closed or the ruby interpreter exits.
    # echo = false and interactive = false
    @r = RinRuby.new(false, false)
    setup_r()
  end

  # Include necessary libraries.
  def setup_r
    include_library("rjson")
  end

  # Include a library after ensuring it has been installed
  def include_library(lib)
    @r.eval "if(!library(#{lib}, logical.return=TRUE)) {install.packages(\"#{lib}\"); library(#{lib});}"
  end

  def eval(str)
    @r.eval str
  end

  # This represents a hash returned as JSON from R but mapped to a
  # Ruby object so we can more easily use it as if it was an R object.
  class Rvalue
    def initialize(hash)
      @___h = hash
      hash.to_a.each do |name, value|
        ruby_name = ___ruby_name(name)
        @___h[ruby_name] = @___h[name] if ruby_name != name
        self.define_singleton_method(ruby_name) {@___h[name]}
      end
    end
    def ___ruby_name(name)
      name.gsub(".", "_")
    end
    def to_h; @___h; end
  end

  # Call an R method named rmethod with (Ruby) arguments. Returns
  # an Integer, Float or an Rvalue (if the returned R value is complex).
  def call(rmethod, *arguments)
    str, args = "", []
    arguments.each_with_index do |arg, index| 
      args << (argname = arg_name(index))
      str += "#{argname} <- fromJSON(\"#{arg.to_json}\");\n"
    end
    resname = res_name(1)
    str += "#{resname} <- toJSON(#{rmethod.to_s}(#{args.join(', ')}));\n"
    @r.eval str
    pull_json_variable(resname)
  end

  # Get the JSON value from a variable in R and parse it back to a Ruby value.
  def pull_json_variable(variableName)
    res = @r.pull(variableName)
    begin
      Rvalue.new JSON.parse(res)
    rescue JSON::ParserError
      # First try to convert to Integer, then Float if it fails.
      begin
        Kernel::Integer(res)
      rescue ArgumentError
        Kernel::Float(res)
      end
    end
  end

  private

  def res_name(index = 1)
    arg_name(index, "res")
  end

  def arg_name(index, prefix = "arg")
    "#{prefix}_#{index}_#{self.object_id}"
  end
end

module Statistics
  # Calc the probability that the unique values in array (or 
  # hash of counts of the values) have (statistically) equal proportions.
  def probability_of_same_proportions(aryOrHashOfCounts)
    counts = (Hash === aryOrHashOfCounts) ? aryOrHashOfCounts : aryOrHashOfCounts.counts
    vs = counts.values
    res = RC.call("prop.test", vs, ([vs.sum] * vs.length))
    res.p_value
  end

  def chi_squared_test(aryOrHashOfCounts)
    counts = (Hash === aryOrHashOfCounts) ? aryOrHashOfCounts : aryOrHashOfCounts.counts
    vs = counts.values
    res = RC.call("chisq.test", vs)
    res.p_value
  end
end

# Make them available at top level
extend Statistics

end

# Create one instance that people can use without having to instantiate.
unless defined?(Kernel::RC)
 Kernel::RC = FeldtRuby::RCommunicator.new
end