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

  def normalize_subsection(data, startIndex, stopIndex)
    subsection = data[startIndex, stopIndex-startIndex]
    mean = subsection.mean
    sub_section = (sub_section - mean(sub_section))/std(sub_section);     
  end
end

end