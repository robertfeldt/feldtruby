require 'open-uri'

module FeldtRuby

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