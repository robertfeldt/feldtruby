require 'minitest/spec'
require 'feldtruby/net/html_doc_getter'

# Skip these network-dependent tests if we have no network connection.
def has_network_connection?
  begin
    open("http://www.google.se")
    return true
  rescue Exception => e
    return false
  end
end

def quicker_has_network_connection?
  reply = `ping -o google.se`
  reply != "" # Is empty if no connection since error is printed on STDERR
end

if quicker_has_network_connection?

  describe "HtmlDocGetter" do
    it "Can get the html page as a string" do
      h = FeldtRuby::HtmlDocGetter.new
      s = h.get("http://www.google.com")
      s.must_be_instance_of String
    end
  
    it "Can get the html page as a Nokogiri doc" do
      h = FeldtRuby::HtmlDocGetter.new
      d = h.get_html_doc("http://www.google.com")
      d.must_be_instance_of Nokogiri::HTML::Document
    end
  end

end