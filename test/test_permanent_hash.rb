require 'feldtruby/permanent_hash'

describe 'PermanentHash' do
  after do
    File.delete(".temp_hash") if File.exist?(".temp_hash")
  end

  it 'works as a hash' do
    ph = FeldtRuby::PermanentHash.new ".temp_hash"

    ph[:a] = 1
    ph[:a].must_equal 1

    ph["b"] = "c"
    ph["b"].must_equal "c"
  end

  it 'is loaded from disk if such a file exists' do
    ph = FeldtRuby::PermanentHash.new ".temp_hash"

    ph[:a] = 1

    ph = nil

    ph2 = FeldtRuby::PermanentHash.new ".temp_hash"

    ph2[:a].must_equal 1
  end
end