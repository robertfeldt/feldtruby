require 'minitest/spec'
require 'feldtruby/word_counter'

describe "WordCounter" do
  it "can count words" do
    wc = FeldtRuby::WordCounter.new
    wc.count_words "The fox likes running. The fox likes it. It feels good for the fox."
    wc.words.sort.must_equal ["feels", "fox", "good", "likes", "running"]
    wc.count("feels").must_equal(1)
    wc.count("fox").must_equal(3)
    wc.count("good").must_equal(1)
    wc.count("likes").must_equal(2)
    wc.count("running").must_equal(1)

    wc.count("notinthere").must_equal(0)
  end

  it "can return a top list of most common words" do
    wc = FeldtRuby::WordCounter.new
    wc.count_words "The fox likes running. The fox likes it. It feels good for the fox."
    t = wc.top_words(1)
    t.must_be_instance_of Array
    t.must_equal [["fox", 3]]
    wc.top_words(2).must_equal [["fox", 3], ["likes", 2]]
  end
end