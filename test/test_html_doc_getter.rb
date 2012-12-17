require 'minitest/spec'
require 'feldtruby/net/html_doc_getter'

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