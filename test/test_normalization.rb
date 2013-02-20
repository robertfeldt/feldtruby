require 'feldtruby/statistics/normalization'

class Array
  def must_be_close_to(other)
    self.zip(other).map {|a,b| a.must_be_close_to(b)}
  end
end

describe "Z normalization" do
  it "handles empty arrays" do
    [].z_normalize.must_equal []
  end

  it "works for Time series 1 from http://code.google.com/p/jmotif/wiki/ZNormalization" do
    data = [2.02, 2.33, 2.99, 6.85, 9.20, 8.80, 7.50, 6.00, 5.85, 3.85, 4.85, 3.85, 2.22, 1.45, 1.34]
    expected = [-0.9796808, -0.8622706, -0.6123005, 0.8496459, 1.739691, 1.588194, 1.095829, 0.5277147, 0.4709033, -0.2865819, 0.0921607, -0.2865819, -0.9039323, -1.195564, -1.237226]
    data.z_normalize.must_be_close_to expected
  end

  it "works for Time series 2 from http://code.google.com/p/jmotif/wiki/ZNormalization" do
    data = [0.50, 1.29, 2.58, 3.83, 3.25, 4.25, 3.83, 5.63, 6.44, 6.25, 8.75, 8.83, 3.25, 0.75, 0.72]
    expected = [-1.289433, -0.9992189, -0.5253246, -0.06612478, -0.2791935, 0.08816637, -0.06612478, 0.595123, 0.8926845, 0.8228861, 1.741286, 1.770675, -0.2791935, -1.197593, -1.208614]
    data.z_normalize.must_be_close_to expected
  end
end