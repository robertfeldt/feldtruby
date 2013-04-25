require 'feldtruby'
require 'feldtruby/file/tempfile'

module FeldtRuby

class CommandRunner
  def initialize(verbose = false, keepAllFiles = false, &block)
    @verbose = verbose
    @keep_all_files = keepAllFiles
    @command_body = block
  end

  # State files that should not be deleted (since they are result files).
  def keep_files(*args)
    puts "Keeping files: #{args}"
    @files_to_keep += args
  end

  def keep_file(filename)
    keep_files filename
  end

  def files_in_dir(dir = ".")
    Dir[dir + "/*"]
  end

  # Start running command.
  def start
    @files_pre = files_in_dir "."
    @files_to_keep = []

    @command_body.call(self)

    delete_files_not_to_be_kept unless @keep_all_files
  end

  # Delete any files in current dir that has been created during the running 
  # of the command, except ones that has been marked as result files to be kept.
  def delete_files_not_to_be_kept
    files_in_dir(".").each do |file|
      next if @files_pre.include?(file) || @files_to_keep.include?(file)
      puts "Deleting file: #{file}"
      File.delete file
    end
  end

  def run *argInstructions

    @command_and_args = argInstructions.map do |ai| 
      (String === ai) ? ai : ai.perform
    end
    @command = @command_and_args.join(" ")

    puts "Running command: #{@command}" if @verbose
    @res = `#{@command}`
    puts "Result was: #{@res}" if @verbose

    @res

  end

  # Write a Ruby object to file and use that file as argument in a command.
  class RubyObjectIntoFileAsArgument
    def initialize(o)
      @object = o
    end

    def perform
      fn = File.unique_filename
      File.open(fn, "w") {|fh| fh.write @object.to_s}
      fn
    end
  end

  # Save ruby object in file and use as argument in running command
  def use_as_file_arg(obj)
    RubyObjectIntoFileAsArgument.new(obj)
  end
end

end