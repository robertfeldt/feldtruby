require 'feldtruby'
require 'nokogiri'
require 'open-uri'

# Fetch html pages from a site but ensure some time between subsequent get operations.
# To minimize the risk that we "annoy" the site operators.
class FeldtRuby::HtmlDocGetter
  def initialize(minTimeBetweenGets = 1.0, maxRandomDelayBetweenGets = 3.0)
    @min_delay = minTimeBetweenGets
    @delta_delay = maxRandomDelayBetweenGets - @min_delay
    @delay_until = Time.now - 1.0 # Ensure no wait the first time
  end
  def get(url)
    wait_until_delay_passed()
    begin
      open(url).read
    ensure
      set_new_delay
    end
  end
  def get_html_doc(url)
    Nokogiri::HTML(get(url))
  end
  def wait_until_delay_passed
    now = Time.now
    sleep(@delay_until - now) if now < @delay_until
  end
  def set_new_delay
    @delay_until = Time.now + (@min_delay + rand() * @delta_delay)
  end
end