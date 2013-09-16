require 'open-uri'
require 'pp'

module FeldtRuby

  # To play nicer with Google we cache the number of hits found for each search term
  # together with a time stamp of when the search was done. Then we only re-search
  # if it is more than 30 days old.
  class GoogleHitsCache
    def initialize(pathToFileWithCachedData = "~/.google_search_cache")
      @path = File.expand_path(pathToFileWithCachedData)
      @hits_and_timestamp = if File.exists?(@path)
          cache_contents_in_file()
         else
           Hash.new
         end
    end

    def google_search_url_for_terms(terms)
      sts = terms.map do |st|
        if st =~ /\s+/ 
          "%22" + st.gsub(/\s+/, "+") + "%22"
        else
          st
        end
      end
      'http://www.google.com/search?as_q=' + sts.join("+")
    end

    SecondsIn30Days = 30*24*60*60

    def has_valid_hits_value?(searchTerms)
      @hits_and_timestamp.has_key?(searchTerms) && (Time.now - @hits_and_timestamp[searchTerms].last < SecondsIn30Days)
    end

    def save_cache_to_file
      File.open(@path, 'w') do|file|
        Marshal.dump(@hits_and_timestamp, file)
      end
    end

    # For debugging purposes we can dump the contents of the file cache.
    def cache_contents_in_file
      File.open(@path) {|fh| Marshal.load(fh)}
    end

    def num_hits(*searchTerms)
      if has_valid_hits_value?(searchTerms)
        @hits_and_timestamp[searchTerms].first
      else
        html = open(google_search_url_for_terms(searchTerms)).read
        if html =~ /About (.+) results/
          hits = $1.gsub(',', '').to_i
          @hits_and_timestamp[searchTerms] = [hits, Time.now]
          save_cache_to_file
          hits
        else
          nil
        end
      end
    end
  end

  # Return the number of hits Google reports for a certain selection of search terms.
  def self.num_google_hits_for_search_terms(*searchTerms)
    sts = searchTerms.map do |st|
      if st =~ /\s+/ 
        "%22" + st.gsub(/\s+/, "+") + "%22"
      else
        st
      end
    end
    html = open('http://www.google.com/search?as_q=' + sts.join("+")).read
    if html =~ /About (.+) results/
      $1.gsub(',', '').to_i
    else
      nil
    end
  end

  # Calculate the NGD (Normalized Google Distance) for two search terms/words.
  def self.ngd(s1, s2)
    l_the =  Math.log2(num_google_hits_for_search_terms("the"))
    l1 =  Math.log2(num_google_hits_for_search_terms(s1))
    l2 =  Math.log2(num_google_hits_for_search_terms(s2))
    l1and2 = Math.log2(num_google_hits_for_search_terms(s1, s2))
    ([l1, l2].max - l1and2) / (l_the - [l1, l2].min)
  end
end