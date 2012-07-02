# Watch directories for changes and provide callback hooks for when files change.
# Partly inspired by and built on code from Autotest/Zentest by Ryan Davis and Eric Hodel.
#
require 'find'

class String
	def starts_with?(str)
		self[0, str.length] == str
	end
end

# Watch for file changes in given paths then call hooks with the updated files.
class FileChangeWatcher
	attr_accessor :find_directories, :last_mtime, :sleep_time, :exclusions

	def initialize(specifiedDirectories = ["."], sleepTime = 5*60, excludeFilesRegexps = [], &runWhenFilesUpdated)
		specified_directories  = specifiedDirectories.reject { |path| path.starts_with?("-") }
		self.find_directories  = specified_directories.empty? ? ['.'] : specified_directories
		self.exclusions = excludeFilesRegexps
		self.sleep_time = sleepTime
		self.last_mtime = nil # Ensure we run first time when started
		@hooks = Hash.new { |h,k| h[k] = [] }
		add_hook :updated, &runWhenFilesUpdated if runWhenFilesUpdated
	end

	# Find the files to process, ignoring temporary files, source
	# configuration management files, etc., and return a Hash mapping
	# filename to modification time.
	def find_files
		result = {}
		targets = self.find_directories
		targets.each do |target|
			Find.find target do |f|
				next if test ?d, f
				next if f =~ /(swp|~|rej|orig)$/ # temporary/patch files
				next if f =~ /^\.\/tmp/          # temporary dir, used by isolate
				next if f =~ /\/\.?#/            # Emacs autosave/cvs merge files
				filename = f.sub(/^\.\//, '')
				result[filename] = File.stat(filename).mtime rescue next
			end
		end
		result
	end

	def exclude_matched_files(files, exclusionRegexps)
		files.reject {|f| exclusionRegexps.any? {|exre| exre.match(f)}}
	end

  	# Find files that has changed since last time. 
  	# Call updated hook if any found.
	def find_updated_files files = find_files
		hook :checkingChanges, files
		updated = self.last_mtime.nil? ? files : files.select { |filename, mtime| self.last_mtime < mtime }
		updated = exclude_matched_files(updated, self.exclusions)

		unless updated.empty? then
			self.last_mtime = Time.now
			hook :updated, updated
		end
	end

	# Add the supplied block to the available hooks, with the given
	# name.
	def add_hook name, &block
		# New hooks added in front
		@hooks[name] = [block] + @hooks[name]
	end

	# Call the event hook named +name+, passing in optional args
	# depending on the hook itself.
	#
	# Returns false if no hook handled the event.
	#
	def hook name, *args
		@hooks[name].any? { |plugin| plugin[self, *args] }
	end

	def wait_for_changes
		hook :waiting
		Kernel.sleep self.sleep_time until find_updated_files
	end
end

if __FILE__ == $0
	dirs_to_watch = ARGV.length > 0 ? ARGV : ["."]
	watcher = FileChangeWatcher.new(dirs_to_watch) {|fwc, ufs| puts ufs.inspect}
	watcher.wait_for_changes
end