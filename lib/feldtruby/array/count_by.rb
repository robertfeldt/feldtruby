class Array
  def count_by(&proc)
    counts = Hash.new(0)
    self.each {|e| counts[proc.call(e)] += 1}
    counts
  end
end