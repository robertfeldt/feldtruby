require 'minitest/unit'
require 'minitest/spec'
require 'feldtruby/statistics'

module MiniTest::Assertions
  # Ensure that that are (statistically) the same number of each type
  # of value in an array.
  def assert_similar_proportions(values, msg = nil)
    #pvalue = FeldtRuby.probability_of_same_proportions(values)
    pvalue = FeldtRuby.chi_squared_test(values)
    assert(pvalue > 0.05, msg || "Proportions differ! p-value is #{pvalue} (<0.05), counts: #{values.counts.inspect}")
  end
end

module MiniTest::Expectations
  infect_an_assertion :assert_similar_proportions, :must_have_similar_proportions
end