if RUBY_VERSION < "1.9"
  puts "ERROR: feldtruby requires Ruby version 1.9"
  exit(-1)
end

# This is the namespace under which we put things...
module FeldtRuby; end