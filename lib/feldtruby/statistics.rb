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

    @installed_libraries = []

    setup_r()

  end

  # Include necessary libraries.
  def setup_r
    include_library("rjson")
  end

  # Include a library after ensuring it has been installed
  def include_library(lib)

    return if @installed_libraries.include?(lib)

    @installed_libraries << lib

    @r.eval "if(!library(#{lib}, logical.return=TRUE)) {install.packages(\"#{lib}\"); library(#{lib});}"

  end

  # Load R scripts in the feldtruby/R directory.
  def load_feldtruby_r_script(scriptName, reload = false)
    @loaded_scripts ||= Array.new # Ensure there is an empty array for loaded script names, if this is first call here.
    return if reload == false && @loaded_scripts.include?(scriptName)
    @loaded_scripts << scriptName
    path = File.join(FeldtRuby::TopDirectory, "R", scriptName)
    @r.eval "source(\"#{path}\")"
  end

  def eval(str)
    @r.eval str
  end

  # Given a script that has variable references in the form "_name_" insert
  # the ruby objects mapped from these names in scriptNameToRubyValues
  def subst_eval(script, scriptNameToRubyValues)

    scriptNameToRubyValues.each do |key, value|

      script = script.gsub("_#{key.to_s}_", ruby_object_to_R_string(value))

    end

    #puts "Eval'ing script:\n#{script}"
    eval script

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

  # Convert a Ruby object of one of the types String, Symbol, Array, Integer 
  # or Float to a String that can be used in R code/scripts to 
  # represent the object.
  def ruby_object_to_R_string(o)

      case o

      when String
        return o.inspect

      when Symbol
        return o.to_s

      when Array
        elems = o.map {|e| ruby_object_to_R_string(e)}.join(", ")
        return "c(#{elems})"

      when Integer
        return o.to_s

      when Float
        return o.to_s

      else
        raise "Cannot represent object #{o} in valid R code"

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
    puts "aryOrHashOfCounts = #{aryOrHashOfCounts}"
    counts = (Hash === aryOrHashOfCounts) ? aryOrHashOfCounts : aryOrHashOfCounts.counts
    vs = counts.values
    res = RC.call("chisq.test", vs)
    res.p_value
  end

  def correlation(ary1, ary2)
    RC.call("cor", ary1, ary2)
  end

  class DiffusionKDE
    attr_reader :densities, :mesh

    # Given a R object with the four sub-values named densities, mesh, sum_density, mesh_interval, min, max
    # we can calculate the probability of new values.
    def initialize(rvalue)
      @probabilities = rvalue.probabilities
      @densities = rvalue.densities
      @mesh = rvalue.mesh
      @mesh_interval = rvalue.mesh_interval.to_f
      @min, @max = rvalue.min.to_f, rvalue.max.to_f
    end

    def density_of(value)
      return 0.0 if value < @min || value > @max
      bin_index = ((value - @min) / @mesh_interval).floor
      @densities[bin_index]
    end

    def probability_of(value)
      return 0.0 if value < @min || value > @max
      bin_index = ((value - @min) / @mesh_interval).floor
      @probabilities[bin_index]
    end
  end

  # Do a kernel density estimation based on the sampled _values_, with n bins (rounded up to nearest exponent of 2)
  # and optional min and max values.
  def density_estimation(values, n = 2**9, min = nil, max = nil)
    # Ensure we have loaded the diffusion.kde code
    RC.load_feldtruby_r_script("diffusion_kde.R")
    args = [values, n]
    if min && max
      args << min
      args << max
    end
    DiffusionKDE.new RC.call("diffusion.kde", *args)
  end
end

# Plotting data sets in R with ggplot2 and save them to files.
module FeldtRuby::Statistics::Plotting

  def gfx_device(format, width = nil, height = nil)

    format = format.to_s            # If given as a symbol instead of a string

    unless GfxFormatToGfxParams.has_key?(format)
      raise ArgumentError.new("Don't now about gfx format #{format}")
    end

    params = GfxFormatToGfxParams[format]

    "#{format}(#{hash_to_R_params(params)})"

  end

  # Map a ruby hash of objects to parameters in R code/script.
  def hash_to_R_params(hash)

    hash.keys.sort.map do |key|

      "#{key.to_s} = #{ruby_object_to_R_string(hash[key])}"

    end.join(", ")

  end

  def plot_2dims(csvFilePath, plotCommand, xlabel, ylabel, title = "scatterplot")

    script = <<-EOS
      data <- read.csv(#{csvFilePath.inspect})
      #{plotCommand}
      #{ggplot2_setup_and_theme()}
      f
    EOS

    subst_eval script, {:title => title,
      :xlabel => xlabel, :ylabel => ylabel}

  end

  def filled_contour(csvFilePath, xlabel, ylabel, title = "filled.contour")
    include_library "MASS"
    #include_library "ggplot2"

    script = <<-EOS
      data <- read.csv(#{csvFilePath.inspect})
      k <- with(data, MASS::kde2d(#{xlabel}, #{ylabel}))
      f <- filled.contour(k, color=topo.colors, 
             plot.title=title(main = _title_),
             xlab=_xlabel_, ylab=_ylabel_)
      f
    EOS

    subst_eval script, {:title => title,
      :xlabel => xlabel.to_s, :ylabel => ylabel.to_s}

  end

  def smooth_scatter_plot(csvFilePath, xlabel, ylabel, title = "smoothscatter")
    include_library "graphics"

    script = <<-EOS
      f <- ggplot(data, aes(#{xlabel}, #{ylabel})) +
             geom_point() + geom_smooth( method="loess", se = FALSE )
    EOS

    plot_2dims(csvFilePath, script, xlabel.to_s, ylabel.to_s, title)
  end

  def hexbin_heatmap(csvFilePath, xlabel, ylabel, title = "heatmap", bins = 50)
    plot_2dims(csvFilePath,
      "f <- ggplot(data, aes(#{xlabel}, #{ylabel})) + geom_hex( bins = #{bins} )",
      xlabel, ylabel, title)
  end

  def scatter_plot(csvFilePath, xlabel, ylabel, title = "scatterplot")

    script = <<-EOS
      smoothing_method <- if(nrow(data) > 1000) {'gam'} else {'loess'}
      f <- ggplot(data, aes(#{xlabel}, #{ylabel})) + geom_point(shape = 1)
      f <- f + stat_smooth(method = smoothing_method)
    EOS

    plot_2dims(csvFilePath, script, xlabel.to_s, ylabel.to_s, title)

  end

  def load_csv_files_as_data(hashWithDataInArrayOrCvsFilePaths, columnName = nil)

    read_csvs = ""
    data_frame = "data.frame(1:length(d0)"

    hashWithDataInArrayOrCvsFilePaths.keys.each_with_index do |key, i|

      value = hashWithDataInArrayOrCvsFilePaths[key]

      set_name = "d#{i}"
      
      read_csvs += "#{set_name} <- "

      if Array === value
        read_csvs += (ruby_object_to_R_string(value) + ";\n")
        data_frame += ", #{key} = #{set_name}"
      else
        read_csvs += "read.csv(#{value.inspect});\n"
        data_frame += ", #{key} = #{set_name}$#{columnName}"
      end

    end

    data_frame += ")"

    script = "#{read_csvs}df <- #{data_frame};"

  end

  def density_tile2d(csvFilePath, xlabel, ylabel, title = "densitytile2d")

    script = <<-EOS
      f <- ggplot(data, aes(x=#{xlabel}, y=#{ylabel}))
      f <- f + stat_density2d(geom="tile", aes(fill=..density..), contour=FALSE) + scale_fill_gradient(high="red", low="white")
    EOS

    plot_2dims(csvFilePath, script, xlabel.to_s, ylabel.to_s, title)

  end

  GfxFormatToGfxParams = {
    "pdf" => {:width => 7, :height => 5, :paper => 'special'},
    "png" => {:units => "cm", :width => 12, :height => 8},
    "tiff" => {:units => "cm", :width => 12, :height => 8},
  }

  # Wrap a sve_graph call around a block that draws a diagram and this will 
  # save the diagram to a file. The filetype is given by the file ending of
  # the file name.
  def save_graph(filename, width = nil, height = nil)

    file_ending = filename.split(".").last

    raise "Don't now about graphics format #{file_ending}" unless GfxFormatToGfxParams.has_key?(file_ending)

    params = GfxFormatToGfxParams[file_ending].clone

    params[:width] = width if width
    params[:height] = height if height

    RC.eval("#{file_ending}(#{filename.inspect}, #{hash_to_R_params(params)})")

    yield() # Just be sure not to nest these save_graph calls within each other...

    RC.eval("dev.off()")

  end

  def ggplot2_setup_and_theme

    include_library("ggplot2")
    include_library("reshape2")

    script = <<-EOS
      f <- f + ggtitle(_title_) + xlab(_xlabel_) + ylab(_ylabel_)
      f <- f + theme_bw()
      f <- f + theme(
              plot.title = element_text(face="bold", size=12), 
              axis.title.x = element_text(face="bold", size=10),
              axis.title.y = element_text(face="bold", size=10)
            )
    EOS

  end

  # Overlaid density graph of the observations (sampled distributions) in data1
  # and data2. The _dataMap_ maps the name of each data series to an array with
  # its observations.
  def overlaid_densities(dataMap, title = "Densities of distributions", datasetsName = "distribution", xlabel = "values", ylabel = "density")

    cardinalities = dataMap.values.map {|vs| vs.length}.uniq

    unless cardinalities.length == 1

      raise ArgumentError.new("Must have same cardinality")

    end

    script = <<-EOS
      df <- data.frame(index = (1:#{cardinalities.first}), #{hash_to_R_params(dataMap)})
      df.m <- melt(df, id = "index")
      names(df.m)[2] <- _datasetsName_
      f <- ggplot(df.m, aes(value, fill=#{datasetsName}))
      f <- f + geom_density(alpha = 0.2, size = 0.5) + scale_color_brewer()
      #{ggplot2_setup_and_theme()}
      f
    EOS

    subst_eval script, {:title => title, :datasetsName => datasetsName,
      :xlabel => xlabel, :ylabel => ylabel}

  end

  # Plot the densities of the data found in the column named _columnName_
  # in the csv files in _csvFiles_.
  def overlaid_densities_from_csv_files(columnName, csvFiles, title = "Densities of distributions", datasetsName = "distribution", xlabel = "values", ylabel = "density")

    read_csvs = ""
    data_frame = "data.frame(1:length(data0)"

    csvFiles.each_with_index do |csvfile, i|
      set_name = "data#{i}"
      read_csvs += "#{set_name} <- read.csv(#{csvfile.inspect}); "
      data_frame += ", d#{i} = #{set_name}$#{columnName}"
    end
    data_frame += ");"

    script = <<-EOS
      #{read_csvs}
      df <- #{data_frame}
      #df <- data.frame(index = (1:#{cardinalities.first}), #{hash_to_R_params(dataMap)})
      df.m <- melt(df, id = "index")
      names(df.m)[2] <- _datasetsName_
      f <- ggplot(df.m, aes(value, fill=#{datasetsName}))
      f <- f + geom_density(alpha = 0.2, size = 0.5) + scale_color_brewer()
      #{ggplot2_setup_and_theme()}
      f
    EOS

    puts script
    subst_eval script, {:title => title, :datasetsName => datasetsName,
      :xlabel => xlabel, :ylabel => ylabel}

  end
end

class FeldtRuby::RCommunicator
  include FeldtRuby::Statistics::Plotting
end

# Make them available at top level
extend Statistics

end

# Create one instance that people can use without having to instantiate.
unless defined?(Kernel::RC)
 Kernel::RC = FeldtRuby::RCommunicator.new
end