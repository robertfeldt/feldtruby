require 'feldtruby/statistics/distance/ncd_external'

DataDir = File.join File.dirname(__FILE__), "data"
Dummy1 = File.join DataDir, "dummy1"
Dummy2 = File.join DataDir, "dummy2"
Dummy3 = File.join DataDir, "dummy3"

DummyFiles = [Dummy1, Dummy2, Dummy3]

describe 'NCDExternal' do
  before do
    @ncd = FeldtRuby::NCDExternal.new("gzip")
  end

  it 'returns a size of a compressed file that is smaller than the original file size' do
    compressed_size = @ncd.compressed_size_of_file(Dummy1)
    compressed_size.must_be :<, File.size?(Dummy1)
  end

  it 'can calc an ncd matrix for a set of files and returns a hash of hashes' do
    m = @ncd.ncd_matrix_for_files DummyFiles
    m.must_be_instance_of Hash
    m.keys.sort.must_equal DummyFiles.sort
    DummyFiles.each do |file|
      m[file].keys.sort.must_equal DummyFiles.sort
    end
  end

  it 'can save an ncd matrix to file' do
    FeldtRuby::NCDExternal.ncd_of_files_in_dirs(DataDir, DataDir, "temp.csv")
    File.exist?("temp.csv").must_equal true
    File.delete "temp.csv"
  end
end