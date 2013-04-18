require 'feldtruby/optimize'
require 'feldtruby/logger'

module FeldtRuby::Optimize

# An archive keeps a record of all "interesting" candidate solutions found
# during optimization. It has two purposes: to contribute to the optimization
# itself (since seeding a search with previously "good" solutions can improve
# convergence speed) but also to provide a current view of the best and most
# interesting solutions found.
#
# Interestingness is hard to define but we posit that two elements are always
# important:
#  1. Being good, i.e. having good values for one or many of the sub-objectives
#  2. Being different, i.e. behaving differently (phenotypic diversity) or 
#       looking different (genotypic diversity), than other candidate solutions.
#
# Different types of optimization can require different trade-offs between 
# these elements but all archives should support both types inherently.
# The default choices for the main class is to use the quality calculated by the
# objective class to judge "being good" and to use a diversity objective to
# judge "being different".
# 
# We also posit that it is not enough only to be diverse (although there is
# some research showing that novelty search in itself may be as good/important
# as directed search) so the default behavior is to only add a solution to the
# diversity top lists if it is within a certain percentage of the best solutions
# on the other (being good) top list. Thus the basic design is to keep one top 
# list per fitness goal, one overall aggregate fitness top list and then one 
# top list per diversity goal.
#
# We note that diversity is just another type of objective (although a relative 
# rather than an absolute one) and we can use the existing
# classes to implement that. A default diversity objective looks at genotypic
# and fitness diversity by default but more elaborate schemes can be used.
#
# One way to make this model easier to understand is to call the three types:
#  generalists    (overall good, aggregated fitness best)
#  specialists    (doing one thing very, very good, sub-objective fitness best)
#  weirdos        (different but with clear qualitites, ok but diverse)
class Archive
  #include FeldtRuby::Logging

  DefaultParams = {
    :NumTopPerGoal => 5, # Number of solutions in top list per individual goal
    :NumTopAggregate => 20, # Number of solutions in top list for aggregate quality

    # Number of solutions in diversity top list. This often needs to 
    # be larger than the other top lists since there are "more" ways to be 
    # diverse than to be good... OTOH it costs CPU power to have large values
    # here since the quality values needs to be recalculated whenever there is
    # a new best. So we keep them small.
    :NumTopDiversityAggregate => 10,

    # Max percent distance (given as a ratio, i.e. 0.05 means 5%) from best 
    # solution (top of Aggregate list) that a solution is allowed to have 
    # to be allowed on the diversity list. If it is more than 5% from best
    # we don't consider adding it to a diversity list.
    :MaxPercentDistanceToBestForDiversity => 0.05
  }

  attr_reader :objective, :diversity_objective

  attr_reader :specialists, :generalists, :weirdos

  def initialize(fitnessObjective, diversityObjective, params = DefaultParams.clone)
    @objective = fitnessObjective
    self.diversity_objective = diversityObjective
    @params = DefaultParams.clone.update(params)
    init_top_lists
  end

  def diversity_objective=(diversityObjective)
    @diversity_objective = diversityObjective
    @diversity_objective.archive = self if @diversity_objective.respond_to?(:archive=)
    @diversity_objective.quality_objective = @objective if @diversity_objective.respond_to?(:quality_objective=)
  end

  def best
    # The top of the Generalists top list is the overall best
    @generalists[0]
  end

  def init_top_lists
    @specialists = Array.new
    @objective.num_goals.times do |i|
      @specialists << GoalTopList.new(@params[:NumTopPerGoal], @objective, i)
    end

    @generalists = GlobalTopList.new(@params[:NumTopAggregate], @objective)

    @weirdos = GlobalTopList.new(@params[:NumTopDiversityAggregate], @diversity_objective)
  end

  # Add a candidate to the top lists if it is good enough to be there. Throws
  # out worse candidates as appropriate.
  def add(candidate)
    @specialists.each {|tl| tl.add(candidate)}

    # Detect if we get a new best one by saving the previous best.
    prev_best = best
    @generalists.add candidate

    # If there was a new best we invalidate the diversity quality values since
    # they are relative and must be recalculated. Note that this might incur
    # a big penalty if there are frequent changes at the top.
    if prev_best != best
#      logger.log_data :new_best, {
#        "New best" => best,
#        "New quality" => @objective.quality_of(best),
#        "Old best" => prev_best,
#        "Old quality" => @objective.quality_of(prev_best)}, 
#        "Archive: New best solution found", true

      @weirdos.each {|w| @diversity_objective.invalidate_quality_of(w)}
    elsif good_enough_quality_to_be_interesting?(candidate)
      # When we add a new one this will lead to re-calc of the diversity quality
      # of the previous ones if there has been a new best since last time.
      @weirdos.add candidate
    end
  end

  # Is quality of candidate good enough (within MaxPercentDistanceToBestForDiversity
  # from quality of best candidate)
  def good_enough_quality_to_be_interesting?(candidate)
    qv_best = @objective.quality_of(best).value
    ((qv_best - @objective.quality_of(candidate).value).abs / qv_best) <= @params[:MaxPercentDistanceToBestForDiversity]
  end

  # A top list is an array of a fixed size that saves the top candidates
  # based on their (aggregate) quality values.
  class GlobalTopList
    def initialize(maxSize, objective)
      @max_size =maxSize
      @top_list = Array.new
      @objective = objective
    end
    def length; @top_list.length; end

    def each
      @top_list.each {|e| yield(e)}
    end

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
end

end