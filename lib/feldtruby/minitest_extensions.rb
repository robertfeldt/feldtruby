require 'minitest/unit'
require 'minitest/spec'
require 'feldtruby/statistics'

module MiniTest::Assertions
  # Ensure that that are (statistically) the same number of each type
  # of value in an array.
  def assert_similar_proportions(values, msg = nil)
    pvalue = FeldtRuby.probability_of_same_proportions(values)
    assert(pvalue >= 0.95, msg || "Proportions differ! p-value that they are the same is #{pvalue} (<0.95)")
  end
end

module MiniTest::Expectations
  infect_an_assertion :assert_similar_proportions, :must_have_similar_proportions
end