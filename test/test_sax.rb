require 'feldtruby/statistics/time_series/sax'
include FeldtRuby::Statistics

describe 'Symbolic Adaptive approXimation - SAX' do
  describe "The standard SymbolMapper, that uses cut points based on Normal/Gaussian distribution" do
    it "accepts alphabet sizes between 2 and 20" do
    end
  end
  
  it "does not accept alphabet sizes larger than 20 or smaller than 2" do
    proc {SAX.new(10, 21)}.must_raise ArgumentError
    proc {SAX.new(3, 1)}.must_raise ArgumentError
  end
end