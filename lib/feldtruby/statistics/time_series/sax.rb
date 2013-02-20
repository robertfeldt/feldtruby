# Implements the basic SAX (Symbolic Adaptive approXimation) from the paper:
#  Jessica Lin, Eamonn Keogh, Stefano Lonardi, Bill Chiu, 
#  "A Symbolic Representation of Time Series, with Implications for Streaming Algorithms", IDMKD 2003.
# available from: http://www.cs.ucr.edu/~eamonn/SAX.pdf
module FeldtRuby

# A SAX object transforms any numeric stream of data (often a time series) 
# of arbitrary length n to a string (symbolic stream) of arbitrary length w,
# where w<n, and typically w<<n. The alphabet size (symbols in the string) is
# also an arbitrary integer a, a>2.
# This allows for many powerful data mining algorithms to be applied and sped up.
class SAX
  # Create a SAX processor with given output length _w_ and alphabet size _a_.
  def initialize(w, a)
    @w, @a = w, a
  end
end

end