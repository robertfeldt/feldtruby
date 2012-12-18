class FeldtRuby::WordCounter
  def initialize
    @counts = Hash.new(0)
  end

  # Ensure it has canonical form
  def preprocess_word(word)
    word.strip.downcase
  end

  def count_word(word)
    w = preprocess_word(word)
    @counts[w] += 1 unless is_stop_word?(w)
  end

  def invidual_words_in_string(str)
    str.downcase.split(/[^\w-]+/)
  end

  def count_words(string)
    invidual_words_in_string(string).map {|w| count_word(w)}
  end

  def words
    @counts.keys
  end

  def count(word)
    @counts[preprocess_word(word)]
  end

  def top_words(numberOfWords)
    @counts.to_a.sort_by {|e| e.last}[-numberOfWords, numberOfWords].reverse
  end

  StopWords = ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "can't", "cannot", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd", "he'll", "he's", "her", "here", "here's", "hers", "herself", "him", "himself", "his", "how", "how's", "i", "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's", "its", "itself", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours ", "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "we're", "we've", "were", "weren't", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's", "whom", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've", "your", "yours", "yourself", "yourselves"]
  
  def is_stop_word?(word)
    StopWords.include?(word)
  end

  # Merge words together that are pluralis or -ing (or -ming) forms of each other.
  # Destructive, so only use this after all words have been added.
  def merge!
    words = @counts.keys
    base_words = words.select {|w| w[-1,1] != "s" && w[-4,4] != "ming" && w[-3,3] != "ing"}
    non_base = words - base_words
    ending_in_s = non_base.select {|w| w[-1,1] == "s"}
    ending_in_ing = non_base.select {|w| w[-3,3] == "ing"}
    ending_in_ming = non_base.select {|w| w[-4,4] == "ming"}
    base_words.each do |base_word|
      merged_word = base_word
      count = @counts[base_word]
      if ending_in_s.include?(base_word + "s")
        count += @counts[base_word + "s"]
        @counts.delete(base_word + "s")
        merged_word += "|#{base_word}s"
      end
      if ending_in_ming.include?(base_word + "ming")
        count += @counts[base_word + "ming"]
        @counts.delete(base_word + "ming")
        merged_word += "|#{base_word}ming"
      end
      if ending_in_ing.include?(base_word + "ing")
        count += @counts[base_word + "ing"]
        @counts.delete(base_word + "ing")
        merged_word += "|#{base_word}ing"
      end
      if merged_word != base_word
        @counts[merged_word] = count
        @counts.delete(base_word)
      end
    end
  end
end

class FeldtRuby::NgramWordCounter < FeldtRuby::WordCounter
  def initialize(n = 2)
    super()
    @n = n
  end
  def count_words(words)
    # Split sentences, get words in each sentence, create n-grams, filter n-grams containing stop words, and count remaining
    words.split(/\.\s+(?=[A-Z]{1})/).each do |sentence|
      ngrams = all_ngrams(invidual_words_in_string(sentence))
      non_stop_ngrams = ngrams.select {|ngram| !ngram.any? {|ngw| is_stop_word?(ngw)}}
      non_stop_ngrams.each {|ngram| count_word(ngram.join(' '))}
    end
  end
  def all_ngrams(array)
    res = []
    length = array.length
    index = 0
    while (length - index) >= @n
      res << array[index, @n]
      index += 1
    end
    res
  end
end