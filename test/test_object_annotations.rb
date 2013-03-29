require 'feldtruby/annotations'

describe "Object annotations" do

  class T
    include FeldtRuby::Annotateable
  end

  it 'can annotate classes' do
    t = T.new
    t._annotations[:a] = 1
    t._annotations[:a].must_equal 1
  end
end