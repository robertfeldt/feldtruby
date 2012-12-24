require 'feldtruby/statistics'

describe "RCommunicator" do
  describe "RValue" do
    it "can be used to access individual elements by their key/name" do
      rv = FeldtRuby::RCommunicator::Rvalue.new({"a" => 1, "b" => "2"})
      rv.a.must_equal 1
      rv.b.must_equal "2"
    end

    it "maps non-ruby method names so they can be used as method names" do
      rv = FeldtRuby::RCommunicator::Rvalue.new({"p.value" => 0.06})
      rv.p_value.must_equal 0.06
    end
  end

  describe "calling simple R functions that returns integers" do
    it "can call sum, min, max etc" do
      RC.call("sum", [1,2,3]).must_equal 6
      RC.call("min", [1,2,3]).must_equal 1
      RC.call("max", [1,2,3]).must_equal 3
    end
  end

  describe "calling simple R functions that returns floats" do
    it "can call sum, min, max etc" do
      RC.call("sum", [1.2, 3.4]).must_equal 4.6
      RC.call("min", [1.2, 3.4]).must_equal 1.2
      RC.call("max", [1.2, 3.4]).must_equal 3.4
    end

    it "can call also with a symbol for the method name" do
      RC.call(:mean, [1,2,3]).must_equal 2.0
    end
  end

  describe "calling R functions that return complex objects" do
    it "can call prop.test" do
      res = RC.call("prop.test", [60, 40], [100, 100])
      res.p_value.must_be_close_to 0.0072
      cilow, cihigh = res.conf_int
      cilow.must_be_close_to 0.0542
      cihigh.must_be_close_to 0.3458
    end
  end
end

describe "Statistics" do
  include FeldtRuby::Statistics
  describe "Proportion testing for the count of values" do
    it "works when counts are explicitly given" do
      # A proportion test checks if the number/proportion of occurences of objects
      # differ. It returns the probability that the proportions are the same
      # given the actual counts.
      probability_of_same_proportions({:a => 50, :b => 50}).must_be_close_to 1.0000
      probability_of_same_proportions({:a => 51, :b => 49}).must_be_close_to 0.8875
      probability_of_same_proportions({:a => 52, :b => 48}).must_be_close_to 0.6714
      probability_of_same_proportions({:a => 53, :b => 47}).must_be_close_to 0.4795
      probability_of_same_proportions({:a => 54, :b => 46}).must_be_close_to 0.3222
      probability_of_same_proportions({:a => 55, :b => 45}).must_be_close_to 0.2031
      probability_of_same_proportions({:a => 56, :b => 44}).must_be_close_to 0.1198
      probability_of_same_proportions({:a => 57, :b => 43}).must_be_close_to 0.0659
      probability_of_same_proportions({:a => 58, :b => 42}).must_be_close_to 0.0339
      probability_of_same_proportions({:a => 59, :b => 41}).must_be_close_to 0.0162
      probability_of_same_proportions({:a => 60, :b => 40}).must_be_close_to 0.0072
    end

    it "works when an array of the actual elements are given" do
      probability_of_same_proportions(([:a] * 570) + ([:b] * 430)).must_be_close_to 5.091e-10
    end
  end
end

require 'feldtruby/minitest_extensions'

describe "Test Statistics but with the extensions to MiniTest framework" do
  it "can use assert_same_proportions" do
    assert_similar_proportions( [1]*10 + [2]*10 )
    # This should fail but I found now way to test it since it uses the MiniTest framework itself...
    # assert_similar_proportions( [1]*60 + [2]*40 )
  end

  it "can use must_have_similar_proportions" do
    ([1]*10 + [2]*10).must_have_similar_proportions
  end
end