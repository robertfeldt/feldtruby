require 'feldtruby/array/basic_stats.rb'

module FeldtRuby

# A ValueArchive keeps basic statistics about values supplied to it in array.
class ValueArchive
  def initialize
    @count = 0
  end

  # Returns the number of times an array has been added to the archive.
  attr_reader :count

  def update(values)
    @count += 1
  end
end

# A PositionBasedValueArchive assumes that each individual position in the supplied
# value arrays have semantic meaning and thus we should not mix properties we calculate
# and save between positions.
class PositionBasedValueArchive < ValueArchive
end

# A MinMaxAveragePerPositionArchive keeps the min, max and average values for each
# position in the supplied arrays. It can thus be used for min-max-normalization
# of values in each position.
class MinMaxAveragePerPositionArchive < PositionBasedValueArchive
  attr_reader :mins, :maxs

  def initialize
    super
    @mins, @maxs, @sums = [], [], []
  end
  def update(values)
    super
    @mins = update_statistic_per_position(@mins, values) {|newold| newold.compact.min}
    @maxs = update_statistic_per_position(@maxs, values) {|newold| newold.compact.max}
    @sums = update_statistic_per_position(@sums, values) {|newold| newold.compact.sum}
  end

  def update_statistic_per_position(currentStatistics, values, &updateStatistic)
    values.zip(currentStatistics).map {|newold| updateStatistic.call(newold)}
  end

  # Return the minimum value we have seen so far in position _index_.
  def min_for_position(index)
    @mins[index]
  end

  # Return the maximum value we have seen so far in position _index_.
  def max_for_position(index)
    @maxs[index]
  end

  # Return the maximum value we have seen so far in position _index_.
  def mean_for_position(index)
    (@sums[index] / @count.to_f) if @sums[index]
  end

  def means
    @sums.map {|v| v/@count.to_f}
  end
end

end