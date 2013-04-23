require 'zlib'

module FeldtRuby::Statistics

module ZlibCompressor
  def compress(s)
    Zlib::Deflate.deflate(s, 9)
  end
end

class StringDistance
  def compressed_length(s)
    compress(s).length
  end

  def distance(str1, str2)
    return 0.0 if str1 == str2
    s1len = compressed_length(str1)
    s2len = compressed_length(str2)
    s1s2len = compressed_length(str1 + str2)
    distance_formula s1len, s2len, s1s2len
  end
end

module NCDFormula
  def distance_formula(s1len, s2len, s1s2len)
    (s1s2len - [s1len, s2len].min).to_f / ([s1len, s2len].max)
  end
end

# Cilibrasi and Vitanyi's NCD.
class NCD < StringDistance
  include ZlibCompressor
  include NCDFormula
end

def ncd(str1, str2)
  (@ncd ||= NCD.new).distance(str1, str2)
end

module CDMFormula
  def distance_formula(s1len, s2len, s1s2len)
    s1s2len.to_f / (s1len + s2len)
  end
end

# Keogh et al's CDM.
class CDM < StringDistance
  include ZlibCompressor
  include CDMFormula
end

def cdm(str1, str2)
  (@cdm ||= CDM.new).distance(str1, str2)
end

class CachingStringDistance < StringDistance
  def initialize(subDistance)
    @sub = subDistance
    @cache_strings = Hash.new
    @cache_pairs = Hash.new
  end

  def compress(s)
    @sub.compress(s)
  end

  def compressed_length(s)
    cached = @cache_strings[s]
    return cached if cached
    @cache_strings[s] = @sub.compressed_length(s)
  end

  def distance(str1, str2)
    cached = @cache_pairs[[str1, str2]]
    return cached if cached
    @cache_pairs[[str1, str2]] = @sub.distance(str1, str2)
  end
end

end