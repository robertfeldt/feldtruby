require 'feldtruby/statistics/clustering'
require 'feldtruby/statistics/euclidean_distance'

describe "Clustering linkage metrics - i.e. distance between clusters of objects in a set" do
  describe "Average linkage metric" do
    it "can be calculated on clusters of with only one number each" do
      alm = FeldtRuby::AverageLinkageMetric.new()
      alm.calc([[1.0]], [[1.0]]).must_equal 0.0
      alm.calc([[0.0]], [[1]]).must_equal 1.0
    end

    it "can be calculated on clusters of with several numbers in them" do
      alm = FeldtRuby::AverageLinkageMetric.new()
      alm.calc([[1], [0]], [[1], [0]]).must_equal 0.5
      alm.calc([[1], [0], [2]], [[1], [0]]).must_equal (5.0/6)
      alm.calc([[1], [0], [2]], [[1], [0], [3]]).must_equal (11.0/9)
    end
  end

  describe "Single linkage metric" do
    it "can be calculated on clusters of with only one float number each" do
      slm = FeldtRuby::SingleLinkageMetric.new()
      slm.calc([[1.0]], [[1.0]]).must_equal 0.0
      slm.calc([[0.0]], [[1.0]]).must_equal 1.0
    end

    it "can be calculated on clusters of with several numbers in them" do
      slm = FeldtRuby::SingleLinkageMetric.new()
      slm.calc([[1], [0]], [[1], [0]]).must_equal 0.0
      slm.calc([[1], [2]], [[1], [0]]).must_equal 0.0
      slm.calc([[1], [2]], [[3], [5]]).must_equal 1.0
      slm.calc([[1], [2], [3]], [[3], [5]]).must_equal 0.0
      slm.calc([[1], [2], [3]], [[6], [7]]).must_equal 3.0
    end
  end

  describe "Complete linkage metric" do
    it "can be calculated on clusters of with only one float number each" do
      clm = FeldtRuby::CompleteLinkageMetric.new()
      clm.calc([[1.0]], [[1.0]]).must_equal 0.0
      clm.calc([[0.0]], [[1.0]]).must_equal 1.0
    end

    it "can be calculated on clusters of with several numbers in them" do
      clm = FeldtRuby::CompleteLinkageMetric.new()
      clm.calc([[1], [0]], [[1], [0]]).must_equal 1.0
      clm.calc([[1], [2]], [[1], [0]]).must_equal 2.0
      clm.calc([[1], [2]], [[3], [5]]).must_equal 4.0
      clm.calc([[1], [2], [3]], [[3], [5]]).must_equal 4.0
      clm.calc([[1], [2], [3]], [[6], [7]]).must_equal 6.0
    end
  end
end