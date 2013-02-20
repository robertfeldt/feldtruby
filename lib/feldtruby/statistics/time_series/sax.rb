require 'feldtruby/statistics/normalization'

# Implements the basic SAX (Symbolic Adaptive approXimation) from the paper:
#  Jessica Lin, Eamonn Keogh, Stefano Lonardi, Bill Chiu, 
#  "A Symbolic Representation of Time Series, with Implications for Streaming Algorithms", IDMKD 2003.
# available from: http://www.cs.ucr.edu/~eamonn/SAX.pdf
module FeldtRuby::Statistics

# A SAX processor transforms any numeric stream of data (often a time series) 
# of arbitrary length n to a string (symbolic stream) of arbitrary length w,
# where w<n, and typically w<<n. The alphabet size (symbols in the string) is
# also an arbitrary integer _a_, a>2. Compared to the SAX described by Keogh et
# al we state the number of data elements, _elementsPerWord_, that should go 
# into each word, i.e. w = n/elementsPerWord.
# This allows for many powerful data mining algorithms to be applied and sped up.
class SAX
  # Create a SAX processor with given output length _w_ and alphabet size _a_.
  def initialize(elementsPerWord, alphabetSize = 6)
    raise ArgumentError if alphabetSize > 20 || alphabetSize < 2
    @elements_per_word, @alphabet_size = elementsPerWord, alphabetSize
  end

  # A mapper maps the values in a subsequence into a symbol. The standard
  # mapper is state-less and normalizes each subsequence and then assumes
  # a normal distribution and thus uses a fixed selection of bins.
  class SymbolMapper
    def initialize(data)
      # This standard mapper does not utilize the whole data sequence to precalc mapping values. But subclasses might.
    end

    # Cut points based on a Normal/Gaussian distribution...
    NormalDistCutPoints = {
        2 => [-Float::INFINITY, 0.00],
        3 => [-Float::INFINITY, -0.43, 0.43],
        4 => [-Float::INFINITY, -0.67, 0.00, 0.67],
        5 => [-Float::INFINITY, -0.84, -0.25, 0.25, 0.84],
        6 => [-Float::INFINITY, -0.97, -0.43, 0.00, 0.43, 0.97],
        7 => [-Float::INFINITY, -1.07, -0.57, -0.18, 0.18, 0.57, 1.07],
        8 => [-Float::INFINITY, -1.15, -0.67, -0.32, 0.00, 0.32, 0.67, 1.15],
        9 => [-Float::INFINITY, -1.22, -0.76, -0.43, -0.14, 0.14, 0.43, 0.76, 1.22],
        10 => [-Float::INFINITY, -1.28, -0.84, -0.52, -0.25, 0.00, 0.25, 0.52, 0.84, 1.28],
        11 => [-Float::INFINITY, -1.34, -0.91, -0.60, -0.35, -0.11, 0.11, 0.35, 0.60, 0.91, 1.34],
        12 => [-Float::INFINITY, -1.38, -0.97, -0.67, -0.43, -0.21, 0.00, 0.21, 0.43, 0.67, 0.97, 1.38],
        13 => [-Float::INFINITY, -1.43, -1.02, -0.74, -0.50, -0.29, -0.10, 0.10, 0.29, 0.50, 0.74, 1.02, 1.43],
        14 => [-Float::INFINITY, -1.47, -1.07, -0.79, -0.57, -0.37, -0.18, 0.00, 0.18, 0.37, 0.57, 0.79, 1.07, 1.47],
        15 => [-Float::INFINITY, -1.5 , -1.11, -0.84, -0.62, -0.43, -0.25, -0.08, 0.08, 0.25, 0.43, 0.62, 0.84, 1.11, 1.50],
        16 => [-Float::INFINITY, -1.53, -1.15, -0.89, -0.67, -0.49, -0.32, -0.16, 0.00, 0.16, 0.32, 0.49, 0.67, 0.89, 1.15, 1.53],
        17 => [-Float::INFINITY, -1.56, -1.19, -0.93, -0.72, -0.54, -0.38, -0.22, -0.07, 0.07, 0.22, 0.38, 0.54, 0.72, 0.93, 1.19, 1.56],
        18 => [-Float::INFINITY, -1.59, -1.22, -0.97, -0.76, -0.59, -0.43, -0.28, -0.14, 0.00, 0.14, 0.28, 0.43, 0.59, 0.76, 0.97, 1.22, 1.59],
        19 => [-Float::INFINITY, -1.62, -1.25, -1.00, -0.80, -0.63, -0.48, -0.34, -0.20, -0.07, 0.07, 0.20, 0.34, 0.48, 0.63, 0.80, 1.0, 1.25, 1.62],
        20 => [-Float::INFINITY, -1.64, -1.28, -1.04, -0.84, -0.67, -0.52, -0.39, -0.25, -0.13, 0.00, 0.13, 0.25, 0.39, 0.52, 0.67, 0.84, 1.04, 1.28, 1.64]
    }

    def supports_alphabet_size?(size)
      NormalDistCutPoints.keys.include? size
    end

    def map_sequence_to_symbol(sequence, alphabet_size)
      symbol_for_value(sequence.mean, alphabet_size)
    end

    def symbol_for_value(value, alphabet_size)
      NormalDistCutPoints[alphabet_size].inject(0) do |symbol, cutpoint|
        return symbol if cutpoint > value
        symbol + 1
      end
    end
  end

  def setup_for_processing_data(data, mapper = nil)
    @mapper ||= SymbolMapper.new(data)
    unless mapper.supports_alphabet_size?(@alphabet_size)
      raise ArgumentError.new("Mapper does not support the alphabet size (#{@alphabet_size}): #{mapper}")
    end
  end

  def process_subsequence(subsequence)
    subsequence = subsequence.z_normalize
    # Note that if the lengths are not evenly divisible the last word will be based on fewer elements. 
    # This is different than the orig SAX as specified in their paper.
    (0..(data.length / @elements_per_word)).map do |wordindex|
      @mapper.map_subsequence_to_symbol(subsequence[wordindex * @elements_per_word, @elements_per_word])
    end
  end

  def process(data, windowSize = data.length, mapper = nil)
    setup_for_processing_data(data, mapper)
    (0..(data.length - windowSize)).map do |i|
      process_subsequence(data[i, windowSize])
    end
  end
end

end