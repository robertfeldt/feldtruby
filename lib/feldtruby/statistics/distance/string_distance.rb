require 'zlib'

module FeldtRuby::Statistics

class StringDistance
  def compress(s)
    Zlib::Deflate.deflate(s, 9)
  end

  def compressed_length(s)
    compress(s).length
  end

  def distance(string1, string2)
    raise NotImplementedError
  end
end

# Cilibrasi and Vitanyi's NCD.
class NormalizedCompressionDistance < StringDistance
  def distance(string1, string2)
    return 0.0 if string1 == string2
    c1 = compressed_length(string1)
    c2 = compressed_length(string2)
    c_1_2 = compressed_length(string1 + string2)
    (c_1_2 - [c1, c2].min).to_f / ([c1, c2].max)
  end
end

def ncd(string1, string2)
  (@ncd ||= NormalizedCompressionDistance.new).distance(string1, string2)
end

# Keogh et al's CDM.
class CompressionBasedDissimilarityMeasure < StringDistance
  def distance(string1, string2)
    return 0.0 if string1 == string2
    c1 = compressed_length(string1)
    c2 = compressed_length(string2)
    c_1_2 = compressed_length(string1 + string2)
    c_1_2.to_f / (c1 + c2)
  end
end

def cdm(string1, string2)
  (@cdm ||= CompressionBasedDissimilarityMeasure.new).distance(string1, string2)
end

end