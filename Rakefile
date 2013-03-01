require "bundler/gem_tasks"

require 'fileutils'

def psys(str)
  puts str
  system str
end

def run_tests(testFiles)
  helper_files = Dir["test/**/*helper*.rb"]
  require_files = (helper_files + testFiles).map {|f| "require \"#{f}\""}.join('; ')
  psys "ruby -Ilib:. -e '#{require_files}' --"
end

desc "Run all tests"
task :test do
  run_tests Dir["test/**/test*.rb"]
end

def filter_latest_changed_files(filenames, numLatestChangedToInclude = 1)
  filenames.sort_by{ |f| File.mtime(f) }[-numLatestChangedToInclude, numLatestChangedToInclude]
end

desc "Run only the latest changed test file"
task :t do
  run_tests filter_latest_changed_files(Dir["test/**/test*.rb"])
end

desc "Run only the latest two changed test file"
task :t2 do
  run_tests filter_latest_changed_files(Dir["test/**/test*.rb"], 2)
end

desc "Clean up intermediate/build files"
task :clean do
  FileUtils.rm_rf "pkg"
end

desc "Clean the repo of any files that should not be checked in"
task :clobber => [:clean]

task :default => :test