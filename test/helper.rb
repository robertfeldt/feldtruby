require 'rubygems'
require 'minitest/autorun'
require 'minitest/spec'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'feldtruby'
require 'feldtruby/minitest_extensions'
require 'feldtruby/optimize'
require 'feldtruby/optimize/objective'

# Common classes used in testing
class MinimizeRMS < FeldtRuby::Optimize::Objective
  def objective_min_rms(candidate)
    candidate.rms
  end
end

class MinimizeRMSAndSum < MinimizeRMS
  def objective_min_sum(candidate)
    candidate.sum.abs
  end
end