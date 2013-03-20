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

	# Change to a float with a given number of significant digits.
	def signif(numDigits = 3)
		self.to_f.signif(numDigits)
	end

	# Change to a float with a given number of significant digits.
	def to_significant_digits(numDigits = 3)
		self.to_f.to_significant_digits(numDigits)
	end
end

class Float
	# Change to a float with a given number of significant digits.
	def signif(numDigits = 3)
		return self if self == INFINITY || self == -INFINITY
		Float("%.#{numDigits}g" % self)
	end

	# Change to a float with a given number of significant digits.
	def to_significant_digits(numDigits = 3)
		signif(numDigits)
	end
end