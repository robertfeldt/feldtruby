require 'feldtruby'

class Numeric
	def round_to_decimals(numDecimals = 2)
		factor = 10**numDecimals
		(self * factor).round / factor.to_f
	end

	def protected_division_with(denom)
		return 0.0 if denom == 0
		self / denom
	end

	def ratio_diff_vs(other)
		(self - other).protected_division_with(other)
	end
end

class Float
	def to_significant_digits(numDigits)
		Float("%.#{numDigits}g" % self)
	end
end