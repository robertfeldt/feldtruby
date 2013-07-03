require 'feldtruby/num_array'

module FeldtRuby

# Object to represent families of locality-sensitive hash functions.
class LocalitySensitiveHashFunctionFamily
  # Given the number of dimensions, i.e. length of the vectors that will later
  # be hashed.
  def initialize(hashFunctionClass, numDimensions, *constants)
    @hash_function_class = hashFunctionClass
    @num_dimensions = numDimensions
    @constants = constants
  end

  # Return a new hash function from the family. It should be a subclass of
  # the HashFunction class.
  def new_hash_function
    @hash_function_class.new(@num_dimensions, *@constants)
  end
end

# HashFunctions are used to map real-valued vectors to (integer) hash values
# for similarity search.
class HashFunction
  attr_reader :num_dimensions
  def initialize(numDimensions)
    @num_dimensions
  end
  # Hash a numeric vector to an integer.
  def hash(numVector)
    raise NotImplementedError # Sub-classes must implement this
  end
end

def rand_vector_of_ones_or_minus_ones(length)
  NumVector[ Array.new(length).map {rand() < 0.5 ? -1 : 1} ].transpose
end

# The RandomProjectionLSHFamily is a family of locality-sensitive hash functions
# based on random project of the vector to be hashed. It is based on the first
# probability distribution for random projection described in the paper:
#  D. Achlioptas, "Database-friendly Random Projections", 2003
#
class AchlioptasHashFunction < HashFunction
  def initialize(numDimensions, w = 4)
    super(numDimensions)
    @w = w
    # Generate a vector of -1 or +1's.
    @projection = rand_vector_of_ones_or_minus_ones(numDimensions)
    @b = rand(@w)
  end

  # Maps to -Inf..Inf since we do not make any assumptions of the values in vector.
  def hash(numVector)
    # Take the dot product of the vector with the projection vector then sum
    # the offest, divide by w and return the integer floor value as the hash.
    ((vector.dot(@projection)[0,0] + @b) / @w).floor
  end
end

# This is the simplified Achlioptas hash function as used in the paper
# Zhang, "HashFile: ...", 2011
# It does not use the b value from the normal Achlioptas hash function.
# A value for W of 100 is shown to be useful in the HashFile paper but this
# depends on the data.
class AchlioptasSimplifiedHashFunction < HashFunction
  def initialize(numDimensions, w = 100)
    super(numDimensions)
    @w = w
    # Generate a vector of -1 or +1's.
    @projection = rand_vector_of_ones_or_minus_ones(numDimensions)
  end

  # Maps to -Inf..Inf since we do not make any assumptions of the values in vector.
  def hash(vector)
    (vector.dot(@projection)[0,0] / @w).floor
  end
end

# This uses one random projection vector per bit of the hash. The random projection
# is based on sampling random values in (-1..1). The sign function is used to
# determine the bit values for the hash.
class SignBasedRandomProjectionHashFunction < HashFunction
  def initialize(numDimensions, numHashBits)
    super(numDimensions)
    @num_hash_bits = numHashBits
    # Random gives values in (0..1) so we extend to the range (-1..1)
    @projection = NMatrix.random([numDimensions, numHashBits]) * 2 - 1
  end

  def hash(vector)
    m = vector.dot(@projection)
    h = 0
    @num_hash_bits.times do |i|
      h = h << 1
      h += 1 if m[0,i] < 0
    end
    h
  end
end

# Data structure for fast similarity search for high-dimensional data in 
# real-valued vector spaces. Inspired by the HashFile paper:
#  Zhang, Agrawal et al (2011), "HashFile : An Efficient Index Structure For Multimedia Data"
class HashFile

  # Both the HashFile and its pages each span a certain range of hash values.
  module HashValueRangeSpanner
    attr_accessor :low_hash_value, :high_hash_value

    # True if we cover a single (integer) hash value.
    def cover_single_hash_value?
      low_hash_value == high_hash_value
    end

    # The parent can ask us if our range of hash values include a given hash 
    # value for its hash function.
    def contains_hash_value?(hashValue)
      high_hash_value >= hashValue && low_hash_value < hashValue
    end
  end

  # A Page is a simple flat array of objects (and their vector and hash value).
  class Page
    include HashValueRangeSpanner

    attr_reader :points

    def initialize(options, lowHashValue, highHashValue, startPoints = [])
      @options = options
      self.low_hash_value, self.high_hash_value = lowHashValue, highHashValue
      @points = startPoints
    end

    # Enumerate the objects and their vectors.
    def each_object_with_vector
      @points.each do |object, hashvalue, vector|
        yield(object, vector)
      end
    end

    # A page is full if it has >= the max number of objects in it.
    def full?
      @points.length >= @options[:MaxObjectsInPage]
    end

    # We split a page in two by sorting its objects on their hash values and then taking half of them
    # into the first page and the rest into the 2nd page.
    def split
      sorted = @points.sort_by {|object, hashvalue, vector| hashvalue}
      len = sorted.length
      mid = len / 2
      split_value = (sorted[mid-1][1] + sorted[mid][1]) / 2.0
      half1, half2 = sorted[0, mid], sorted[mid, len - mid]
      return Page.new(@options, low_hash_value, split_value, half1), Page.new(@options, split_value, high_hash_value, half2)
    end

    def add_object_with_hash(object, hashvalue, vector)
      @points << [object, hashvalue, vector]
    end
  end

  include HashValueRangeSpanner

  Options = {
    :MaxObjectsInPage => 32,
    :HashWindowSize => 25, # ~100 was the optimal value in the HashFile paper but they used large databases so we use lower
    :NumDimensions => 10,
    :HashFunctionClass => AchlioptasSimplifiedHashFunction,
    :ObjectToVector => proc {|o| o} # We use an identity function to map objects to their vectors.
  }

  def initialize(options = {}, lowHashValue = -Float::INFINITY, highHashValue = Float::INFINITY)
    @options = Options.clone.update(options)

    # This is the range for the parent hash file node. The root node has an infinite range as default.
    @low_hash_value, @high_hash_value = lowHashValue, highHashValue

    # Create a hash function for this HashFile (node).
    @hash_function = @options[:HashFunctionClass].new @options[:NumDimensions], @options[:HashWindowSize]

    # The children of a HashFile are either Pages or other HashFiles.
    # They are sorted based on their hash value range. At the outset we have a 
    # single page child with an inifinite hash range. The page is empty.
    @children = [Page.new(@options, -Float::INFINITY, Float::INFINITY)]
  end

  # A HashFile is never full, i.e. can always accept another object.
  def full?
    false
  end

  def each_object_with_vector
    @children.each do |child|
      child.each_object_with_vector {|e| yield(e)}
    end
  end

  # Add an object to the hashfile. Objects are indexed based on a unique
  # vector which is attached to it.
  def add(object)
    add_object_with_hash object, object_to_vector(object)
  end

  def add_object_with_hash(object, hashvalue, vector)
    # We always use our own hash function if we are a HashFile so disregard the one sent in.
    add_object_with_vector object, vector
  end

  def add_object_with_vector(object, vector)
    hashvalue = hash(vector)
    child, index = find_child(hashvalue)
    if child.full?
      if child.cover_single_hash_value?

        # Child is full and cover a single hash value => create new hash file.
        nhf = @children[index] = HashFile.new @options, child.low_hash_value, child.high_hash_value

        # Copy over all objects from the previous page to the new hash file.
        child.each_object_with_vector {|o,v| nhf.add_object_with_vector(o, v)}

        # Now add the new object. We don't send the hash along since the new hashfile
        # has a new hash function.
        nhf.add_object_with_vector object, vector

      else

        # Child page is full but covers more than single value so we split it 
        # and insert the new pages where the previous one was => keeps children 
        # sorted.
        @children[index, 1] = child.split

        # Now insert the new object where it belongs
        if @children[index].contains_hash_value?(hashvalue)
          @children[index].add_object_with_hash object, hashvalue, vector
        else
          @children[index+1].add_object_with_hash object, hashvalue, vector
        end

      end
    else
      child.add_object_with_hash(object, hashvalue, vector)
    end
  end

  # Find the child corresponding to the given hash value.
  def find_child(hashValue)
    # Linear scan of children until we find the one that contains our
    # hash value.
    @children.each_with_index do |child, index|
      if child.contains_hash_value?(hashValue)
        return child, index
      end
    end
    raise "No child found that contains hash value #{hashValue}"
  end

  # The method for mapping an object to the vector it will be indexed on.
  # Default is to use the object itself, i.e. objects are vectors. Override
  # for more complex schemes.
  def object_to_vector(o)
    @options[:ObjectToVector].call(o)
  end
end

end