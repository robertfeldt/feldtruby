# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'feldtruby/version'

Gem::Specification.new do |gem|
  gem.name          = "feldtruby"
  gem.version       = FeldtRuby::VERSION
  gem.authors       = ["Robert Feldt"]
  gem.email         = ["robert.feldt@gmail.com"]
  gem.description   = %q{Robert Feldt's Common Ruby Code lib}
  gem.summary       = %q{Robert Feldt's Common Ruby Code lib}
  gem.homepage      = "https://github.com/robertfeldt/feldtruby"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('rinruby')

  gem.add_dependency('json')

  gem.add_dependency('nokogiri')

  # For mongodb_logger:
  gem.add_dependency('mongo')

  # bson_ext does not work with macruby but good for MongoDB performance so:
  gem.add_dependency('bson_ext')
end
