require 'feldtruby/statistics/distance/ngd'

describe 'Number of hits in a Google search' do
  it "gives roughly the right number for a search for Robert Feldt as we got 2013-09-16 11:36 (17,900)" do
    rfhits = FeldtRuby.num_google_hits_for_search_terms("Robert Feldt")
    rfhits.class.must_equal Fixnum
    rfhits.must_be :<, 4e4
    rfhits.must_be :>, 1e4
  end
end

describe "NGD - Normalized Google Distance" do
  describe "pairwise" do
    it "correctly calculates the semantic distance between red and blue (was 0.03 on 2013-09-16)" do
      nh_the =  25270000000
      nh_red =  4260000000
      nh_blue = 4070000000
      nh_red_and_blue = 4000000000
      ngd_red_and_blue = ([Math.log2(nh_red), Math.log2(nh_blue)].max - Math.log2(nh_red_and_blue)) / (Math.log2(nh_the) - [Math.log2(nh_red), Math.log2(nh_blue)].min)
      ngd_calculated = FeldtRuby.ngd("red", "blue")
      ngd_calculated.class.must_equal Float
      # We have to use a large delta since the number of hits varies quite a lot.
      ngd_calculated.must_be_within_delta ngd_red_and_blue, 0.03
    end
  end
end