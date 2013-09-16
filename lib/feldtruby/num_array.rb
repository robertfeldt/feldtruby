require 'feldtruby'
# This uses NMatrix if available, otherwise NArray with Ruby's built in
# Matrix and Vector as backup if none of the others are available.

# 1. Try to load NMatrix
begin
  require 'nmatrix'
  FeldtRuby::NMatrixAvailable = true

  class FeldtRuby::NumVector < NVector
    def self.[](values)
      # We must use a NMatrix if length is only 1 since NVector does not support it...
      if values.length == 1
        N[ values ]
      else
        self.new(values.length, values)
      end
    end

    def length
      shape().max
    end
  end

rescue LoadError
  FeldtRuby::NMatrixAvailable = false
end

# 2. If NMatrix was not available try to load NArray.
unless FeldtRuby::NMatrixAvailable

  begin
    require 'narray'
    FeldtRuby::NArrayAvailable = true

    class FeldtRuby::NumVector < NVector
    end

  rescue LoadError
    FeldtRuby::NArrayAvailable = false
  end

end

# 3. If neither NMatrix or NArray was available we fall back on pure ruby
# implementations.
if !FeldtRuby::NMatrixAvailable && !FeldtRuby::NArrayAvailable

  class FeldtRuby::NumVector < Matrix
    # Matrix multiplication is named dot in NMatrix so we adhere to that. Ruby's 
    # Matrix class uses the normal multiplication for this...
    def dot(other)
      self * other
    end
  end

end