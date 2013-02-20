require 'feldtruby/statistics/distance/string_distance'
include FeldtRuby::Statistics

describe "ncd" do
  it "gives no distance if the strings are the same" do
    ncd("aaa", "aaa").must_equal 0.0
  end

  it "gives distance > 0.0 if strings are not the same" do
    ncd("a", "b").must_be :>, 0.0
    ncd("aa", "ab").must_be :>, 0.0
  end
end

describe "cdm" do
  it "gives no distance if the strings are the same" do
    cdm("aaa", "aaa").must_equal 0.0
  end

  it "gives distance > 0.0 if strings are not the same" do
    cdm("a", "b").must_be :>, 0.0
    cdm("aa", "ab").must_be :>, 0.0
  end  
end