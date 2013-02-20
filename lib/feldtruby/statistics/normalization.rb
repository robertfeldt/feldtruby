require 'feldtruby/array/basic_stats'

# The normalization methods assumes the existence of basic statistics
# on the class it they are included in:
#   z_normalize: require mean and stdev
module FeldtRuby::Normalization
  def normalize(&transform)
    self.map {|v| transform.call(v)}
  end

  def z_normalize
    mean, stdev = self.mean, self.sd
    self.map {|e| (e-mean)/stdev}
  end

  def min_max_normalize
    return [] if self.length == 0
    min = self.min.to_f
    range = self.max - min
    self.map {|e| (e-min)/range}
  end
end

class Array
  include FeldtRuby::Normalization
end