require 'feldtruby/statistics/design_of_experiments'

describe 'Latin Hypercube Sampling' do
  it "can sample in a rectangular multi-dim bounding box" do
    params = {
      :a => [0,100],
      :b => [0,50],
      :c => [0.0, 1.0]
    }
    candidates = RC.latin_hypercube_sample_of_parameters(params, 100)
    candidates.must_be_instance_of Hash
    candidates.keys.sort.must_equal params.keys.sort

    candidates[:a].must_be_instance_of Array
    candidates[:a].length.must_equal 100
    candidates[:a].each do |a|
      a.must_be :>=, 0
      a.must_be :<=, 100
    end

    candidates[:b].must_be_instance_of Array
    candidates[:b].length.must_equal 100
    candidates[:b].each do |b|
      b.must_be :>=, 0
      b.must_be :<=, 50
    end

    candidates[:c].must_be_instance_of Array
    candidates[:c].length.must_equal 100
    candidates[:c].each do |b|
      b.must_be :>=, 0.0
      b.must_be :<=, 1.0
    end
  end
end