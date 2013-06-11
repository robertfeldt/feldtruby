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

desc "Run tests separately to identify problematic ones"
task :test_sep do
  Dir["test/**/test*.rb"].each do |fn|
    puts "RUNNING: #{fn}"
    run_tests [fn]
  end
end

desc "Run all normal tests"
task :test do
  run_tests Dir["test/test*.rb"]
end

desc "Run long-running tests"
task :testlong do
  run_tests Dir["test/long_running/test*.rb"]
end

desc "Run all tests"
task :testall do
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

def profile_script(script, args = [])
  ts = Time.now.strftime("%y%m%d_%H%M%S")
  scriptname = File.basename(script)
  profile = "./profiling/#{scriptname}_profile_#{ts}"

  template = <<-EOS
    require 'perftools'

    PerfTools::CpuProfiler.start("PROFILENAME")
    require "SCRIPT"
    PerfTools::CpuProfiler.stop
  EOS
  profiling_script = template.gsub("PROFILENAME", profile).gsub("SCRIPT", script)
  puts profiling_script
  filename = "profiling/profiling_script.rb"
  File.open(filename, "w") {|fh| fh.puts profiling_script}
  psys "ruby #{filename} #{args.join(' ')}"
  psys "pprof.rb --text #{profile} > #{profile}.txt"
  psys "pprof.rb --pdf #{profile} > #{profile}.pdf"
  File.delete(filename)
end

desc "Profile"
task :profile do
  unless require("perftools")
    puts "CANNOT profile since perftools.rb is NOT INSTALLED."
    exit -1
  end
  profile_script "./spikes/simple_de_run.rb", ["100_000"]
  profile_script "./spikes/long_running_search.rb"
end

desc "Update the build date for the gem"
task :update_build_date do
  version_file = File.join(".", "lib", "feldtruby", "version.rb")
  lines = File.readlines(version_file)
  lines = lines.map do |line|
    if line =~ /(\s*)GemBuildDate = "(.*)"/
      timestamp = Time.new.strftime "%Y-%m-%d %H:%M.%S"
      "#{$1}GemBuildDate = #{timestamp.inspect}\n"
    else
      line
    end
  end
  File.open(version_file, "w") {|fh| fh.write lines.join()}
end

desc "Update build date then build and install gem"
task :uinstall => [:update_build_date, :install] do
  # Nothing to do! Work is done by the two other tasks...
end

desc "Update build date then release the gem"
task :urelease => [:update_build_date, :release] do
  # Nothing to do! Work is done by the two other tasks...
end

desc "Clean the repo of any files that should not be checked in"
task :clobber => [:clean] do
  system "rm -rf profiling/*"
end

task :default => :test