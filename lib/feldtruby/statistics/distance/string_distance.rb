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

# Cilibrasi and Vitanyi's NCD, using Zlib for compression.
class NCD_Zlib < StringDistance
  include ZlibCompressor
  include NCDFormula
end
# Zlib is the default compressor.
NCD = NCD_Zlib

def ncd(str1, str2)
  (@ncd ||= NCD.new).distance(str1, str2)
end

module CDMFormula
  def distance_formula(s1len, s2len, s1s2len)
    s1s2len.to_f / (s1len + s2len)
  end
end

# Keogh et al's CDM, using Zlib for compression.
class CDM_Zlib < StringDistance
  include ZlibCompressor
  include CDMFormula
end
# Zlib is the default compressor.
CDM = CDM_Zlib

def cdm(str1, str2)
  (@cdm ||= CDM.new).distance(str1, str2)
end

# If ruby-xz is installed and we can load it (requires also liblzma to be 
# installed) then we add a XZ compressor.
XZInstalled = require("xz")
if XZInstalled
  module XZCompressor
    def compress(s)
      XZ.compress(s)
    end
  end

  # NCD using XZ compression; better but slower.
  class NCD_XZ < NCD
    include XZCompressor
  end

  # CDM using XZ compression; better but slower.
  class CDM_XZ < CDM
    include XZCompressor
  end
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
    s1len = compressed_length(str1)
    s2len = compressed_length(str2)
    s1s2len = compressed_length(str1 + str2)
    @cache_pairs[[str1, str2]] = @sub.distance_formula s1len, s2len, s1s2len
  end

  def in_cache?(str)
    @cache_strings.has_key?(str) || @cache_pairs.has_key?(str)
  end
end

end