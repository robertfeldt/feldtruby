module FeldtRuby

# Hash that saves permanently to disk and reloads given a filepath.
# Typically use case: cache on disk so that we do not need to recompute
# file-specific information unless a file has changed.
#
# Note! Not meant for large hashes since it saves frequently to disk!
#
class PermanentHash
  def initialize(filepath, hash = {})
    @filepath, @hash = filepath, nil
    if File.exist?(filepath)
      begin
        @hash = Marshal.load(File.read(filepath))
      ensure
        if @hash == nil || @hash.class != Hash
          @hash = {}
        end
      end
    else
      @hash = hash
    end
  end
  
  def save_to_file()
    File.open(@filepath, "w") {|fh| fh.write Marshal.dump(@hash)}
  end
  
  def []=(key, value)
    res = ( @hash[key] = value )
    save_to_file()
    res
  end
  
  def [](key)
    @hash[key]
  end
  
  def clear
    res = @hash.clear
    save_to_file()
    res
  end
  
  def length; @hash.length; end
  def has_key?(key); @hash.has_key?(key); end  
  def inspect; @hash.inspect; end
  def hash; @hash; end
end

end