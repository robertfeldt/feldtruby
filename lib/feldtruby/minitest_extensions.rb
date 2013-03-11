require 'minitest/unit'
require 'minitest/spec'
require 'feldtruby/statistics'

module MiniTest::Assertions
  # Ensure that that are (statistically) the same number of each type
  # of value in an array.
  def assert_similar_proportions(values, expectedPValue = 0.01, msg = nil)
    #pvalue = FeldtRuby.probability_of_same_proportions(values)
    pvalue = FeldtRuby.chi_squared_test(values)
    assert(pvalue > expectedPValue, msg || "Proportions differ! p-value is #{pvalue} (<0.05), counts: #{values.counts.inspect}")
  end

  def assert_falsey(value, msg = nil)
    assert(value.!, msg || "#{value} is not falsey (it is #{value})")
  end

  def assert_truthy(value, msg = nil)
    assert(value, msg || "#{value} is not truthy (it is #{value})")
  end
end

NumTestRepetitions = 50

def repeatedly_it(message, &testcode)
  NumTestRepetitions.times do |i|
    it("#{i}: " + message, &testcode)
  end
end

module MiniTest::Expectations
  infect_an_assertion :assert_similar_proportions, :must_have_similar_proportions
  infect_an_assertion :assert_falsey, :must_be_falsey
  infect_an_assertion :assert_truthy, :must_be_truthy
end