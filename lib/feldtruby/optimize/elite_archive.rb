require 'feldtruby/optimize'

module FeldtRuby::Optimize

# This keeps a record of the best/elite candidate solutions found during
# an optimization search. It keeps separate top lists per goal being optimized
# as well as for the aggregate quality value (fitness) itself. The top lists
# are all sorted to allow for fast checks and insertion.
class EliteArchive
  DefaultParams = {
    :NumTopPerGoal => 10,
    :NumTopAggregate => 25
  }

  attr_reader :objective, :top_per_goal, :best

  def initialize(objective, options = DefaultParams.clone)
    @objective = objective
    @options = options
    init_top_lists
  end

  # A top list is an array of a fixed size that saves the top candidates
  # based on their quality values.
  class GlobalTopList
    def initialize(maxSize, objective)
      @max_size =maxSize
      @top_list = Array.new
      @objective = objective
    end
    def length; @top_list.length; end

    def [](index)
      @top_list[index]
    end

    def add(candidate)
      last = @top_list.last
      #puts "In #{self},\nlast = #{last}, candidate = #{candidate}, top_list = #{@top_list}"
      if @top_list.length < @max_size || last.nil? || is_better_than?(candidate, last)
        @top_list.pop if @top_list.length >= @max_size
        @top_list << candidate
        @top_list = sort_top_list
      end
      #puts "top_list = #{@top_list}"
    end

    def is_better_than?(candidate1, candidate2)
      @objective.is_better_than?(candidate1, candidate2)
    end

    def sort_top_list
      @top_list.sort_by {|c| @objective.quality_of(c).value}
    end

    def inspect
      self.class.inspect + @top_list.inspect
    end
  end

  class GoalTopList < GlobalTopList
    def initialize(maxSize, objective, goalIndex)
      super(maxSize, objective)
      @index = goalIndex
    end
    def is_better_than?(candidate1, candidate2)
      @objective.is_better_than_for_goal?(@index, candidate1, candidate2)
    end
    def sort_top_list
      @top_list.sort_by {|c| 
        qv = @objective.quality_of(c)
        qv.sub_quality(@index, true) # We want the sub quality value posed as a minimization goal regardless of whether it is a min or max goal
      }
    end
  end

  def init_top_lists
    @top_per_goal = Array.new
    @objective.num_goals.times do |i|
      @top_per_goal << GoalTopList.new(@options[:NumTopPerGoal], @objective, i)
    end
    @best = GlobalTopList.new(@options[:NumTopAggregate], @objective)
  end

  def add(candidate)
    @best.add candidate
    @top_per_goal.each {|tl| tl.add(candidate)}
  end
end

end