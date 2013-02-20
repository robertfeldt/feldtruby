require 'feldtruby/statistics/time_series/sax'
include FeldtRuby::Statistics

describe 'Symbolic Adaptive approXimation - SAX' do
  describe "The standard SAX SymbolMapper, that uses cut points based on Normal/Gaussian distribution" do
    it "accepts alphabet sizes between 2 and 20" do
      sm = SAX::SymbolMapper.new
      sm.supports_alphabet_size?(-1).must_equal false
      sm.supports_alphabet_size?(0).must_equal false
      sm.supports_alphabet_size?(1).must_equal false
      sm.supports_alphabet_size?(2).must_equal true
      sm.supports_alphabet_size?(20).must_equal true
      sm.supports_alphabet_size?(21).must_equal false
    end

    it "maps correctly to symbols for alphabet of size 2" do
      sm = SAX::SymbolMapper.new
      sm.symbol_for_value(-10, 2).must_equal 1
      sm.symbol_for_value(-1, 2).must_equal 1
      sm.symbol_for_value(1, 2).must_equal 2
      sm.symbol_for_value(10, 2).must_equal 2
    end

    it "maps correctly to symbols for alphabet of size 4" do
      sm = SAX::SymbolMapper.new
      sm.symbol_for_value(-0.7, 4).must_equal 1
      sm.symbol_for_value(-0.5, 4).must_equal 2
      sm.symbol_for_value(-0.01, 4).must_equal 2
      sm.symbol_for_value(0, 4).must_equal 3
      sm.symbol_for_value(0.01, 4).must_equal 3
      sm.symbol_for_value(0.5, 4).must_equal 3
      sm.symbol_for_value(0.7, 4).must_equal 4
      sm.symbol_for_value(17, 4).must_equal 4
    end
  end

  it "does not accept alphabet sizes larger than 20 or smaller than 2" do
    proc {SAX.new(10, 21)}.must_raise ArgumentError
    proc {SAX.new(3, 1)}.must_raise ArgumentError
  end

  it "maps some simple time series to symbols" do
    sax = SAX.new(1, 4)
    sax.process([-1, 0, 1]).must_equal [1,3,4]
  end
end