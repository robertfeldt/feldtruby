require 'feldtruby'

class Numeric
	def round_to_decimals(numDecimals = 2)
		factor = 10**numDecimals
		(self * factor).round / factor.to_f
	end
end