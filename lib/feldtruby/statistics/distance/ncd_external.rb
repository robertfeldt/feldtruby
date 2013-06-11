# We will fall back on the internal NCD compressor unless one of the external 
# ones is available.
require 'feldtruby/statistics/distance/string_distance'
require 'feldtruby/permanent_hash'

module FeldtRuby

# NCD class for calculating the Normalized Compression Distance of files via
# external compressor programs. At least one of the compressors need to be installed of them is not
# available we cannot calculate NCD.
# Uses a cache so that multiple calls to NCD does NOT recompress files 
# that have not changed.
class NCDExternal
  # These are the compressors we "know" about (i.e. can use) but not all of them might be available on your computer.
  COMPRESSORS = {
    "gzip" => {
      :compress => "gzip -9", 
      :decompress => "gzip -d", 
      :file_ending => ".gz"},
    "bzip2" => {
      :compress => "bzip2 -9", 
      :decompress => "bzip2 -d", 
      :file_ending => ".bz2"},
    "xz" => {
      :compress => "xz -e", 
      :decompress => "xz -d", 
      :file_ending => ".xz"},
    "zpaq" => {
      :compress => "lrzip -z -L 9 -U", # Uses the best zpaq compression but is slow on large files
      :decompress => "lrzip -d", 
      :file_ending => ".lrz"},
    "lzo" => {
      :compress => "lrzip -l -L 9 -U", # Uses the lzo ultra fast compressor but not as good as zpaq
      :decompress => "lrzip -d", 
      :file_ending => ".lrz"},
    "bzip2-lrzip" => {
      :compress => "lrzip -b -L 9 -U", # Uses the bzip2 compression in lrzip
      :decompress => "lrzip -d", 
      :file_ending => ".lrz"},
    "gzip-lrzip" => {
      :compress => "lrzip -g -L 9 -U", # Uses the gzip compression in lrzip
      :decompress => "lrzip -d", 
      :file_ending => ".lrz"},
  }

  # Preferred compressors should be listed in decreasing priority in this array. 
  # The better compressing ones should generally be listed before ones that compress less.
  COMPRESSOR_PREFERENCE_ORDER = ["zpaq", "xz", "bzip2", "bzip2-lrzip", "gzip", "gzip-lrzip", "lzo"]

  def self.compressors_we_know_about
    COMPRESSORS.keys
  end
  
  def self.available_compressors
    ncd = NCDExternal.new(nil)
    puts "Checking which of the known compressors are actually installed on this computer."
    COMPRESSOR_PREFERENCE_ORDER.select do |c|
      ncd.compressor_is_available?(c)
    end
  end
  
  attr_accessor :compressor
  
  NCDCacheFileName = "./.ncd_file_cache"

  def initialize(compressor = nil, cacheName = NCDCacheFileName, verbose = false)
    @num_compressions, @num_decompressions = 0, 0
    @verbose = verbose
    @default_compressor = @compressor = compressor
    if compressor && !compressor_is_available?(compressor)
      raise ArgumentError, "Compressor #{compressor} is not available!!"
    end
    @size_cache = FeldtRuby::PermanentHash.new(cacheName)
  end
  
  def pv(str)
    puts(str) if @verbose
  end

  def compressor_is_available?(compressor)
    return false unless COMPRESSORS.keys.include?(compressor)
    pv "\nCheck if compressor #{compressor} is available on this machine."
    self.compressor = compressor
    tempfilename, res = unique_filename(), false
    File.open(tempfilename, "w") {|fh| fh.write "sdgjeiwolflvkdsnvkdsnvkdsnlkvjdlsfjlewjf"}
    res = compress_file(tempfilename) {|cfilename| true}
    delete_file(tempfilename)
    return res
  end

  # Compare the compressors that we support. !Utility function!
  def compare_compressors(filename)
    pv "Compare compressors on #{filename}."
    pv "#{filename}: size = #{orig_size = file_size(filename)}."
    self.class.available_compressors.each do |compressor|
      @compressor = compressor
      pv "Compressing file #{filename} with #{compressor}."
      size = compressed_size_of_file(filename)
      pv( "#{compressor}: size = #{size} (%.2f%%)" % (-(orig_size-size.to_f)/orig_size*100.0))
    end
    @compressor = @default_compressor
    pv ""
    STDOUT.flush
  end
  
  # Calculate the NCD of two files.
  def ncd_of_files(filepath1, filepath2)
    size1 = compressed_size_of_file(filepath1)
    size2 = compressed_size_of_file(filepath2)
    size12 = compressed_size_of_concatenated_files(filepath1, filepath2)
    ncd_calc(size1, size2, size12)
  end

  # Calculate the NCD based on the compressed sizes of two strings x and y as well as the compressed size of the two strings concatenated.
  def ncd_calc(sx, sy, sxy)
    ary = [sx, sy]
    (sxy - ary.min) / ary.max.to_f
  end

  # Return true if a file (or two if two is given), in its/their latest saved versions, is/are in the cache.
  def file_is_cached?(filepath, filepath2 = nil)
    key1, key2 = filekeys(filepath, filepath2)
    @size_cache.has_key?(key1) && @size_cache[key1].has_key?(key2)
  end

  # Create a unique key of the date/times in a stat object for a file.
  def statkey(filepath)
    # For some reason the following raises and Errno::ENOENT error that a file
    # does not exist when called a second time after is actually returned the file.
    # For now we work around this "bug" by returning a dummy modification time.
    #File.stat(filepath).mtime.to_s
    "dummy"
  end

  # Create two keys from a filepath and a compressor (or from two filepaths and a compressor if two are given).
  # The generated keys are unique for each unique saved version of the file(s) => can be used as keys in the
  # size cache
  def filekeys(filepath, filepath2 = nil)
    if filepath2 == nil
      return (filepath + compressor.to_s), statkey(filepath)
    else
      return (filepath + "!!-! MERGED !!-!! " + filepath2 + compressor.to_s), (statkey(filepath) + statkey(filepath2))
    end
  end
  
  # Return the cached size for a file (or two files if two are given).
  def cached_size(filepath, filepath2 = nil)
    key1, key2 = filekeys(filepath, filepath2)
    @size_cache[key1][key2]
  end

  # Cache the size for a file (or for the merged version of two files if two are given).
  def cache_size(size, filepath, filepath2 = nil)
    key1, key2 = filekeys(filepath, filepath2)
    @size_cache[key1] = (@size_cache[key1] || {}).update( {key2 => size} )
  end

  # Get the size of two files that are concatenated.
  def compressed_size_of_concatenated_files(filepath1, filepath2)
    return cached_size(filepath1, filepath2) if file_is_cached?(filepath1, filepath2)
    begin
      merged_filepath = merge_files(filepath1, filepath2)
      size = compressed_size_of_file(merged_filepath)
      cache_size(size, filepath1, filepath2)
    ensure
      delete_file(merged_filepath) if merged_filepath && File.exist?(merged_filepath)
    end
    size
  end

  # Get the size of the file after being compressed with _compressor_.
  def compressed_size_of_file(filepath)
    return cached_size(filepath) if file_is_cached?(filepath)
    compress_file(filepath) do |cfilename|
      size = file_size(cfilename)
      cache_size(size, filepath)
      size
    end
  end

  def compress_file(filepath)
    res = nil
    begin
      cfilename = compress_with_compressor(filepath, compressor)
      if File.exist?(cfilename)
        res = yield(cfilename)
      else
        res = nil # Indicates that there was a problem, typically that compressor was not available
      end
    ensure
      decompress_file(cfilename, compressor) if !File.exist?(filepath) && File.exist?(cfilename)
      delete_file(cfilename) if File.exist?(cfilename)
    end
    return res
  end

  def decompress_file(filepath, compressor)
    system(COMPRESSORS[compressor][:decompress] + " #{filepath}")    
  end

  def compress_with_compressor(filepath, compressor)
    system(COMPRESSORS[compressor][:compress] + " #{filepath}")
    compressed_filename(filepath, compressor)
  end
  
  def compressed_filename(filename, compressor = nil)
    filename + COMPRESSORS[compressor][:file_ending]
  end

  def file_size(filename)
    File.stat(filename).size
  end
    
  def delete_file(filename)
    File.delete(filename) if File.exist?(filename)
  end
  
  def unique_filename(baseName = "temp")
    begin
      baseName = baseName + rand(1e4).to_s
    end while File.exist?(baseName)
    baseName
  end
  
  def merge_files(filename1, filename2)
    tempfilename = unique_filename()
    system "cat #{filename1} > #{tempfilename}"
    system "cat #{filename2} >> #{tempfilename}"
    tempfilename
  end

  # Calculate the ncd matrix for a set of files (or between all pairs of files from two sets of files if two sets are given).
  def ncd_matrix_for_files(files1, files2 = nil)
    files2 ||= files1
    ncds = Hash.new
    files1.each do |f1|
      ncds[f1] ||= Hash.new
      files2.each do |f2|
        ncds[f2] ||= Hash.new
        if f1 == f2
          ncds[f1][f2] = 0.0
        else
          dist = ncd_of_files(f1, f2)
          ncds[f2][f1] = ncds[f1][f2] = dist
        end
      end
    end
    ncds
  end
  
  # Main method that finds the files and then calculates the ncd values and outputs to a file.
  def self.ncd_of_files_in_dirs(dir1, dir2, matrixFilename = "dist_matrix.csv", separator = ",", compressor = "gzip", csvHeader = false, stripPaths = false, numFilesToSample = nil)
    ncd = NCD.new(compressor)
    files1 = Dir[dir1 + "/*"]
    files2 = Dir[dir2 + "/*"]
    if numFilesToSample
      files1 = files1.sort_by {rand()}.take(numFilesToSample)
      if dir2 == dir1
        files2 = files1
      else
        files2 = files2.sort_by {rand()}.take(numFilesToSample)
      end
    end
    ncd_matrix = ncd.ncd_matrix_for_files(ncd, files1, files2)
    File.open(matrixFilename, "w") do |fh|
      if csvHeader == true
        if stripPaths
          fps = files2.map {|fp| File.basename(fp)}
        else
          fps = files2
        end
        fh.puts( "Filename," + fps.join(separator) )
      end
      files1.each do |f1|
        if stripPaths
          filename = File.basename(f1)
        else
          filename = f1
        end
        fh.puts( "#{filename}#{separator}" + files2.map {|f2| ncd_matrix[f1][f2]}.join(separator) )
      end  
    end
    return ncd_matrix
  end  
end

end