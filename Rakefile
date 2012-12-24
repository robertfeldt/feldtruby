require "bundler/gem_tasks"

require 'fileutils'

def psys(str)
  puts str
  system str
end

desc "Run all tests"
task :test do
  helper_files = Dir["test/**/*helper*.rb"]
  test_files = Dir["test/**/test*.rb"]
  require_files = (helper_files + test_files).map {|f| "require \"#{f}\""}.join('; ')
  psys "ruby -Ilib:. -e '#{require_files}' --"
end

desc "Clean up intermediate/build files"
task :clean do
  FileUtils.rm_rf "pkg"
end

desc "Clean the repo of any files that should not be checked in"
task :clobber => [:clean]

task :default => :test