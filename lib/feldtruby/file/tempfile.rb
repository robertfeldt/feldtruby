# Create a unique filename in the current dir.
def File.unique_filename(suffix = ".temp", basename = "temp")
	tempfilename = basename + rand(1e7).to_s + suffix
	while Dir.exist?(tempfilename)
		tempfilename = basename + rand(1e7).to_s + suffix
	end
	tempfilename
end

# Find a unique temp file name starting with _basename_
# and having a file suffix _suffix_, then supply it to a block. 
# After the block has executed make sure there is no tempfile 
# with that name, if there is delete it.
def File.with_tempfile(suffix = ".temp", basename = "temp")
	tempfilename = unique_filename
	begin
		yield tempfilename
	ensure
		File.delete(tempfilename) if Dir.exist?(tempfilename)
	end
end

# Find a unique temp file name in the same way as for with_tempfile
# but now save a string to that file before supplying the filename
# to the block. 
def File.with_tempfile_containing(contents, suffix = ".temp", basename = "temp")
	File.with_tempfile do |tempfilename|
		File.open(tempfilename, "w") {|fh| fh.write(contents)}
		yield tempfilename
	end
end