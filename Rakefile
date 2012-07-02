# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "feldtruby"
  gem.homepage = "http://github.com/robertfeldt/feldtruby"
  gem.license = "MIT"
  gem.summary = %Q{Robert Feldt's Common Ruby Code lib - collecting the stuff I write again and again}
  gem.description = %Q{Robert Feldt's Common Ruby Code lib. I will gradually collect the many generally useful Ruby tidbits I have laying around and clean them up into here. Don't want to rewrite these things again and again...}
  gem.email = "robert.feldt@gmail.com"
  gem.authors = ["Robert Feldt"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

# rcov not supported in Ruby 1.9 so we must select based on version
if ENV['RUBY_VERSION'] < "1.9"
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
    test.rcov_opts << '--exclude "gems/*"'
  end
else
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "feldtruby #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end