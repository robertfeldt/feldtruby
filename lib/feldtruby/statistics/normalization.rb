require 'feldtruby/array/basic_stats'

# The normalization methods assumes the existence of basic statistics
# on the class it they are included in:
#   z_normalize: require mean and stdev
module FeldtRuby::Normalization
  def z_normalize
    mean, stdev = self.mean, self.sd
    self.map {|e| (e-mean)/stdev}
  end
end

class Array
  include FeldtRuby::Normalization
end