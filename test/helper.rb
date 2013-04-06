require 'rubygems'
require 'minitest/autorun'
require 'minitest/spec'

FeldtRubyTestDir = File.dirname(__FILE__)
FeldtRubyLibDir = File.join(FeldtRubyTestDir, '..', 'lib')
FeldtRubyLongTestDir = File.join(FeldtRubyTestDir, 'long_running')

$LOAD_PATH.unshift FeldtRubyLibDir
$LOAD_PATH.unshift FeldtRubyTestDir
$LOAD_PATH.unshift FeldtRubyLongTestDir

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