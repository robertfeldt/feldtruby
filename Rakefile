require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  # test_files = FileList['test/logging_test_runner.rb'] + FileList['test/test*.rb']
  test_files = FileList['test/test*.rb']
  t.test_files = test_files
  t.verbose = true
end

task :default => :test