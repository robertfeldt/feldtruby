require 'feldtruby/statistics/distance/locality_sensitive_hashing'
include FeldtRuby

def rand_vector(len)
  FeldtRuby::NumVector[ Array.new(len).map {rand()} ]
end

def rand_vectors(numVectors, vectorLength)
  Array.new(numVectors).map {rand_vector(vectorLength)}
end

# Generate random hash values from a hash function of the given type.
def generate_random_hash_values(numValues, hashFunctionClass, numDims, numBits)
  family = LocalitySensitiveHashFunctionFamily.new hashFunctionClass, numDims, numBits
  hf = family.new_hash_function()
  numValues.times do
    hv = hf.hash(rand_vector(numDims))
    yield hv
  end
end

describe SignBasedRandomProjectionHashFunction do
  it "can create new hash functions from a hash function family, regardless of num dimensions and hash length" do
    (1..10).each do |numDimensions|
      (1..33).each do |numHashBits|
        family = LocalitySensitiveHashFunctionFamily.new SignBasedRandomProjectionHashFunction, numDimensions, numHashBits
        hf = family.new_hash_function()
        hf.must_be_instance_of SignBasedRandomProjectionHashFunction
        hv = hf.hash(rv = rand_vector(numDimensions))
        hv.must_be_instance_of Fixnum
        hv.must_be :<, (2**numHashBits) 
        hv.must_be :>=, 0 
      end
    end
  end

  it "always generates hash values that are within bounds" do
    dims = 1 + rand(200)
    bits = 1 + rand(80)
    generate_random_hash_values(1000, SignBasedRandomProjectionHashFunction, dims, bits) do |hv|
      hv.must_be :<, (2**bits) 
      hv.must_be :>=, 0 
    end
  end
end

def sample_from(n, array)
  array.to_a.sort_by {rand()}.take(n)
end

describe AchlioptasSimplifiedHashFunction do
  it "can create new hash functions from a hash function family, regardless of num dimensions and hash length" do
    sample_from(10, 1..200).each do |numDimensions|
      sample_from(10, 1..1000).each do |w|
        family = LocalitySensitiveHashFunctionFamily.new AchlioptasSimplifiedHashFunction, numDimensions, w
        hf = family.new_hash_function()
        hf.must_be_instance_of AchlioptasSimplifiedHashFunction
        hv = hf.hash(rv = rand_vector(numDimensions))
        hv.must_be_instance_of Fixnum
      end
    end
  end
end

describe HashFile do
  describe HashFile::Page do
    before do
      @p = HashFile::Page.new({:MaxObjectsInPage => 2}, -1, 1)
    end

    it "is not full until the max size reached" do
      @p.full?.must_equal false

      @p.add_object_with_hash 1, 1, 1
      @p.full?.must_equal false

      @p.add_object_with_hash 2, 2, 2
      @p.full?.must_equal true
    end

    it "contains hash values that are inside its range" do
      @p.contains_hash_value?(0).must_equal true
      @p.contains_hash_value?(0.5).must_equal true
      @p.contains_hash_value?(-0.5).must_equal true
    end

    it "contains the hash value that are on its upper range" do
      @p.contains_hash_value?(1).must_equal true
    end

    it "does not contain hash values that are on or lower than its lower range" do
      @p.contains_hash_value?(-1).must_equal false
      @p.contains_hash_value?(-10).must_equal false
      @p.contains_hash_value?(-456).must_equal false
    end

    it "does not contain hash values that are over its high range" do
      @p.contains_hash_value?(1.1).must_equal false
      @p.contains_hash_value?(2).must_equal false
      @p.contains_hash_value?(3525).must_equal false
    end

    it "can enumerate the objects it contains" do
      p = HashFile::Page.new({:MaxObjectsInPage => 32}, -100, 100)
      (1..10).each {|v| p.add_object_with_hash(v,v,100+v)}
      values = []
      p.each_object_with_vector {|o,v| values << [o,v]}
      values.length.must_equal 10
      values[0].must_equal [1,101]
    end

    it "can split itself in two when there it has an uneven number of points" do
      p = HashFile::Page.new({:MaxObjectsInPage => 32}, -100, 100)

      (1..3).each {|v| p.add_object_with_hash(v,v,100+v)}

      c1, c2 = p.split

      c1.must_be_instance_of HashFile::Page
      c2.must_be_instance_of HashFile::Page

      c1.low_hash_value.must_equal -100
      c1.high_hash_value.must_equal 1.5

      c2.low_hash_value.must_equal 1.5
      c2.high_hash_value.must_equal 100

      c1.points.length.must_equal 1
      c2.points.length.must_equal 2

      c1.points[0].must_equal [1,1,101]

      c2.points[0].must_equal [2,2,102]
      c2.points[1].must_equal [3,3,103]
    end

    it "can split itself in two when there it has an even number of points" do
      p = HashFile::Page.new({:MaxObjectsInPage => 32}, -756, 542)

      (10..13).each {|v| p.add_object_with_hash(v,v,100+v)}

      c1, c2 = p.split

      c1.must_be_instance_of HashFile::Page
      c2.must_be_instance_of HashFile::Page

      c1.low_hash_value.must_equal -756
      c1.high_hash_value.must_equal 11.5

      c2.low_hash_value.must_equal 11.5
      c2.high_hash_value.must_equal 542

      c1.points.length.must_equal 2
      c2.points.length.must_equal 2

      c1.points[0].must_equal [10, 10, 110]
      c1.points[1].must_equal [11, 11, 111]

      c2.points[0].must_equal [12, 12, 112]
      c2.points[1].must_equal [13, 13, 113]
    end
  end

  it "accepts data points and can later enumerate them" do
    dims = 1 + rand(200)

    hf = HashFile.new( {:NumDimensions => dims} )

    hf.must_be_instance_of HashFile

    vectors = rand_vectors(2000, dims)
    vectors.each {|v| hf.add(v)}

    hf.points.length.must_equal vectors.length
  end

  it "can delete objects and then they are not found" do
    dims = 1 + rand(200)

    hf = HashFile.new( {:NumDimensions => dims} )

    vectors = rand_vectors 3, dims
    
    hf.add(vectors[0])
    hf.add(vectors[1])
    hf.add(vectors[2])

    hf.include?(vectors[0]).must_equal true
    hf.include?(vectors[1]).must_equal true
    hf.include?(vectors[2]).must_equal true

    hf.delete(vectors[0])
    hf.include?(vectors[0]).must_equal false
    hf.include?(vectors[1]).must_equal true
    hf.include?(vectors[2]).must_equal true

    hf.add(vectors[0])
    hf.delete(vectors[1])
    hf.delete(vectors[2])
    hf.include?(vectors[0]).must_equal true
    hf.include?(vectors[1]).must_equal false
    hf.include?(vectors[2]).must_equal false

    hf.add(vectors[2])
    hf.include?(vectors[0]).must_equal true
    hf.include?(vectors[1]).must_equal false
    hf.include?(vectors[2]).must_equal true
  end
end
