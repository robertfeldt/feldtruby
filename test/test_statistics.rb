require 'feldtruby/statistics'

describe "RCommunicator" do
  describe "RValue" do
    it "can be used to access individual elements by their key/name" do
      rv = FeldtRuby::RCommunicator::Rvalue.new({"a" => 1, "b" => "2"})
      rv.a.must_equal 1
      rv.b.must_equal "2"
    end

    it "maps non-ruby method names so they can be used as method names" do
      rv = FeldtRuby::RCommunicator::Rvalue.new({"p.value" => 0.06})
      rv.p_value.must_equal 0.06
    end
  end

  describe "calling simple R functions that returns integers" do
    it "can call sum, min, max etc" do
      RC.call("sum", [1,2,3]).must_equal 6
      RC.call("min", [1,2,3]).must_equal 1
      RC.call("max", [1,2,3]).must_equal 3
    end
  end

  describe "calling simple R functions that returns floats" do
    it "can call sum, min, max etc" do
      RC.call("sum", [1.2, 3.4]).must_equal 4.6
      RC.call("min", [1.2, 3.4]).must_equal 1.2
      RC.call("max", [1.2, 3.4]).must_equal 3.4
    end

    it "can call also with a symbol for the method name" do
      RC.call(:mean, [1,2,3]).must_equal 2.0
    end
  end

  describe "calling R functions that return complex objects" do
    it "can call prop.test" do
      res = RC.call("prop.test", [60, 40], [100, 100])
      res.p_value.must_be_close_to 0.0072
      cilow, cihigh = res.conf_int
      cilow.must_be_close_to 0.0542
      cihigh.must_be_close_to 0.3458
    end
  end
end

describe "Statistics" do
  include FeldtRuby::Statistics
  describe "Proportion testing for the count of values" do
    it "works when counts are explicitly given" do
      # A proportion test checks if the number/proportion of occurences of objects
      # differ. It returns the probability that the proportions are the same
      # given the actual counts.
      probability_of_same_proportions({:a => 50, :b => 50}).must_be_close_to 1.0000
      probability_of_same_proportions({:a => 51, :b => 49}).must_be_close_to 0.8875
      probability_of_same_proportions({:a => 52, :b => 48}).must_be_close_to 0.6714
      probability_of_same_proportions({:a => 53, :b => 47}).must_be_close_to 0.4795
      probability_of_same_proportions({:a => 54, :b => 46}).must_be_close_to 0.3222
      probability_of_same_proportions({:a => 55, :b => 45}).must_be_close_to 0.2031
      probability_of_same_proportions({:a => 56, :b => 44}).must_be_close_to 0.1198
      probability_of_same_proportions({:a => 57, :b => 43}).must_be_close_to 0.0659
      probability_of_same_proportions({:a => 58, :b => 42}).must_be_close_to 0.0339
      probability_of_same_proportions({:a => 59, :b => 41}).must_be_close_to 0.0162
      probability_of_same_proportions({:a => 60, :b => 40}).must_be_close_to 0.0072
    end

    it "works when an array of the actual elements are given" do
      probability_of_same_proportions(([:a] * 570) + ([:b] * 430)).must_be_close_to 5.091e-10
    end
  end

  describe "Diffusions Kernel Density Estimation based on R code loaded from the feldtruby R directory" do
    it "works for simple examples" do
      data = [1]
      kde = density_estimation(data, 4, 0.0, 3.0)
      kde.mesh.must_equal [0.0, 1.0, 2.0, 3.0]
      kde.densities.length.must_equal 4
      kde.densities[0].must_be_close_to 0.3912
      kde.densities[1].must_be_close_to 0.3591
      kde.densities[2].must_be_close_to 0.3101
      kde.densities[3].must_be_close_to 0.2728
    end
  end
end

require 'feldtruby/minitest_extensions'

describe "Test Statistics but with the extensions to MiniTest framework" do
  it "can use assert_same_proportions" do
    assert_similar_proportions( [1]*10 + [2]*10 )
    # This should fail but I found no way to test it since it uses the MiniTest framework itself...
    # assert_similar_proportions( [1]*60 + [2]*40 )
  end

  it "can use must_have_similar_proportions" do
    ([1]*10 + [2]*10).must_have_similar_proportions
  end
end

describe "Plotting" do

  it "can map Ruby integers to R code/script strings" do

    RC.ruby_object_to_R_string(1).must_equal "1"
    RC.ruby_object_to_R_string(42).must_equal "42"

  end

  it "can map Ruby floats to R code/script strings" do

    RC.ruby_object_to_R_string(3.675).must_equal "3.675"
    RC.ruby_object_to_R_string(1e10).must_equal "10000000000.0"

  end

  it "can map Ruby arrays to R code/script strings" do

    RC.ruby_object_to_R_string([1,2,3]).must_equal "c(1, 2, 3)"
    RC.ruby_object_to_R_string([10, 1.65]).must_equal "c(10, 1.65)"

  end

  it "can map Ruby strings to R code/script strings" do

    RC.ruby_object_to_R_string("loess").must_equal '"loess"'
    RC.ruby_object_to_R_string("gam").must_equal '"gam"'

  end

  it "can convert a hash of Ruby objects into a R parameter script" do

    RC.hash_to_R_params({:a => 1, :b => 42.5}).must_equal "a = 1, b = 42.5"

    s = RC.hash_to_R_params({:b => "b", :height => [5, 7.2]})
    s.must_equal 'b = "b", height = c(5, 7.2)'

  end

  it "can change the file ending if is not what is expected" do

  end

  it "can do a scatter plot" do

    d = File.dirname(__FILE__) + "/"
    filename = d + "tmp.csv"

    out = "scatterplot.pdf"

    RC.save_graph(out) do
      RC.scatter_plot(filename, "size", "height", "Scatterplot")
    end

    File.exist?(out).must_equal true

    #File.delete out

  end

  it "can do a hexbin heatmap plot" do

    d = File.dirname(__FILE__) + "/"
    filename = d + "tmp.csv"

    out = "hexbin.pdf"

    RC.save_graph(out) do
      RC.hexbin_heatmap(filename, "size", "height", 
        "Hexbin heatmap", 30)
    end

    File.exist?(out).must_equal true

    File.delete out

  end

  it "can do overlaid density plot of three arrays" do

    d1 = Array.new(100) {rand(10)}
    d2 = Array.new(100) {2 + rand(6)}
    g = Array.new(100) {1 + rand(12)}

    out = "tmp2.pdf"

    RC.save_graph(out) do
      RC.overlaid_densities({:ind1 => d1, :ind2 => d2, :goal => g})
    end

    File.exist?(out).must_equal true
    File.delete out

  end
end