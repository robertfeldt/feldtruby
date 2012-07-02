# Minimal info to dump circos conf files, for beautiful rendering of
# circular data visualizations.
class Circos
	class Chromosome < Hash
		attr_reader :bands
		def initialize(*args, &block)
			super
			@bands = Hash.new
		end
		def dump_to_circos_data(keyOrder = nil)
			keyOrder ||= self.keys.sort
			(name + keyOrder.map {|key| self[key]}).join(" ") + "\n"
		end
		def dump_bands_to_circos(bandKeyOrder = nil)
			bands.map {|b| b.dump_to_circos_data(bandKeyOrder)}.join("\n")
		end
	end
	class Band < Hash
		attr_reader :name
		def dump_to_circos_data(keyOrder = nil)
			keyOrder ||= self.keys.sort
			(name + keyOrder.map {|key| self[key]}).join(" ")
		end
	end
end
