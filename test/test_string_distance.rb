require 'feldtruby/statistics/distance/string_distance'
include FeldtRuby::Statistics

describe "ncd" do
  it "gives no distance if the strings are the same" do
    ncd("aaa", "aaa").must_equal 0.0
  end

  it "gives distance > 0.0 if strings are not the same" do
    ncd("a", "b").must_be :>, 0.0
    ncd("aa", "ab").must_be :>, 0.0
  end
end

describe "cdm" do
  it "gives no distance if the strings are the same" do
    cdm("aaa", "aaa").must_equal 0.0
  end

  it "gives distance > 0.0 if strings are not the same" do
    cdm("a", "b").must_be :>, 0.0
    cdm("aa", "ab").must_be :>, 0.0
  end  
end

def rand_string(length)
  chars = ('a'..'z').to_a
  num_chars = chars.length
  Array.new(length).map {chars[rand(num_chars)]}.join
end

def time_block(&block)
  start = Time.now
  res = block.call
  elapsed = Time.now - start
  return res, elapsed 
end

describe "CachingStringDistance" do
  it "is quicker the second time we call it with very large strings" do

    csd = CachingStringDistance.new(NCD.new)

    100.times do
      s1 = rand_string(1e3)
      s2 = rand_string(1e3)
      res, elapsed = time_block {csd.distance(s1, s2)}
      res2, elapsed2 = time_block {csd.distance(s1, s2)}
      res.must_equal res2
      elapsed2.must_be :<, elapsed
    end
    
  end
end