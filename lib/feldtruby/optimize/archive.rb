require 'feldtruby/optimize'
require 'feldtruby/logger'
require 'feldtruby/json'

module FeldtRuby::Optimize

# An archive keeps a record of all "interesting" candidate solutions found
# during optimization or identified by a user. It has two purposes: to contribute 
# to the optimization itself (since seeding a search with previously "good" 
# solutions can improve convergence speed) but also to provide a current view of 
# the best and most interesting solutions found.
class Archive
  include FeldtRuby::Logging
  include ToJsonImplementedViaDataHash

  DefaultParams = {}

  def initialize(fitnessObjective, params = {})
    @objective = fitnessObjective
    @params = DefaultParams.clone.update(params)
    setup_logger_and_distribute_to_instance_variables(@params)
  end

  # Every archive must have at least one objective which is used to exclude
  # objects outright if they are "too far" from the best candidates.
  attr_reader :objective

  # Possibly add candidate if it is considered "interesting".
  def add_if_interesting(candidate)
    raise NotImplementedError
  end

  # Return info about all candidates and their quality values. The info is 
  # returned as a hash for each candidate.
  # tagged with a "type"
  def info_about_all_candidates
    raise NotImplementedError
  end
end

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
class DiversityArchive < Archive
  DefaultParams = {
    :NumTopPerGoal => 10, # Number of solutions in top list per individual goal
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

  attr_reader :diversity_objective
  attr_reader :specialists, :generalists, :weirdos

  def initialize(fitnessObjective, diversityObjective, params = {})
    super(fitnessObjective, DefaultParams.clone.update(params))
    self.diversity_objective = diversityObjective
    init_top_lists
    setup_logger_and_distribute_to_instance_variables(@params)
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

    @weirdos = WeirdoTopList.new(@params[:NumTopDiversityAggregate], @diversity_objective, @objective)
  end

  # Add a candidate to the top lists if it is good enough to be there. Throws
  # out worse candidates as appropriate.
  def add_if_interesting(candidate)
    @specialists.each {|tl| tl.add(candidate)}

    # Detect if we get a new best one by saving the previous best.
    prev_best = best
    @generalists.add candidate

    # If there was a new best we invalidate the diversity quality values since
    # they are relative and must be recalculated. Note that this might incur
    # a big penalty if there are frequent changes at the top.
    if prev_best != best
      prev_qv = prev_best.nil? ? "" : @objective.quality_of(prev_best)
      logger.log_data :new_best, {
        "New best" => best,
        "New quality" => @objective.quality_of(best),
        "Old best" => prev_best,
        "Old quality" => prev_qv}, "Archive: New best solution found", true

      # We must delete weirdos that are no longer good enough to be on the 
      # weirdos list.
      to_delete = []
      @weirdos.each {|w| 
        # Invalidate quality since it must now be re-calculated (since it will
        # typically depend on the best and we have a new best...)
        @diversity_objective.invalidate_quality_of(w)

        to_delete << w unless good_enough_quality_to_be_interesting?(w)
      }
      #puts "Deleting #{to_delete.length} out of #{@weirdos.length} weirdos"
      #@weirdos.delete_candidates(to_delete)

    elsif good_enough_quality_to_be_interesting?(candidate)
      # When we add a new one this will lead to re-calc of the diversity quality
      # of the previous ones if there has been a new best since last time.
      @weirdos.add candidate
    end
  end

  # Return array with info about all candidates in archive. Tags them with type
  # (which list they are on), position on that list and index among lists (only
  # relevant for specialists, for the others its 0).
  def info_about_all_candidates
    index = 0
    gcs = candidates_to_array(generalists, "generalist")
    gcs_indexes = gcs.map {|qvh| qvh["id"]}
    gcs + candidates_to_array(weirdos, "weirdo") + 
      specialists.map do |s|
        cs = candidates_to_array(s, "specialist", (index+=1))
        # We must filter out the specialists that are already among the generalists
        cs.select {|qvh| !gcs_indexes.include?(qvh["id"])}
      end.flatten
  end

  def candidates_to_array(topList, name, index = 0)
    h = topList.data_to_json_hash
    qvs = h['quality_values']
    res = []
    qvs.zip((1..(qvs.length)).to_a) do |qv,i|
      h = qv.data_to_json_hash
      h["pos"] = i
      h["type"] = name
      h["list_index"] = index if name == "specialist"
      res << h
    end
    res
  end

  # Is quality of candidate good enough (within MaxPercentDistanceToBestForDiversity
  # from quality of best candidate)
  def good_enough_quality_to_be_interesting?(candidate)
    qv_best = @objective.quality_of(best).display_value
    qv = @objective.quality_of(candidate).display_value
    res = ((qv_best - qv).abs / qv_best) <= @params[:MaxPercentDistanceToBestForDiversity]
    #puts "qvbest = #{qv_best}, qv = #{qv}, res = #{res}"
    res
  end

  # A top list is an array of a fixed size that saves the top candidates
  # based on their (aggregate) quality values.
  class GlobalTopList
    include ToJsonImplementedViaDataHash

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
      if @top_list.length < @max_size || last.nil? || is_better_than?(candidate, last)
        @top_list.pop if @top_list.length >= @max_size
        @top_list << candidate
        @top_list = sort_top_list
      end
    end

    def is_better_than?(candidate1, candidate2)
      @objective.is_better_than?(candidate1, candidate2)
    end

    def delete_candidates(candidates)
      @top_list = @top_list - candidates
    end

    def sort_top_list
      @top_list.sort_by {|c| @objective.quality_of(c).value}
    end

    def inspect
      self.class.inspect + @top_list.inspect
    end

    def data_to_json_hash
      {
        'max_size' => @max_size,
        'top_list' => @top_list,
        'quality_values' => @top_list.map {|c| @objective.quality_of(c)},
        'objective' => @objective
      }
    end
  end

  class WeirdoTopList < GlobalTopList
    def initialize(maxSize, diversityObjective, qualityObjective)
      super(maxSize, diversityObjective)
      @quality_objective = qualityObjective
    end

    def data_to_json_hash
      h = super()
      # Since the diversity objective is used to sort the weirdos their
      # 'quality_values' are actually the diversity quality values.
      h['diversity_quality_values'] = h['quality_values']
      h['quality_values'] = @top_list.map {|c| @quality_objective.quality_of(c)}
      h
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

    # We add additional data about which goal/objective we are a top list for.
    def data_to_json_hash
      h = super()
      h['objective_index'] = @index
      h['objective_name'] = @objective.goal_methods[@index]
      h
    end
  end

  def data_to_json_hash
    { 'generalists' => @generalists,
      'specialists' => @specialists,
      'weirdos'     => @weirdos}
  end
end

# A Nondominated archive keeps all candidates that are non-dominated up to a certain
# size.
class NondominatedArchive < Archive
  DefaultParams = {
    :NumCandidates => 100
  }

  def initialize(fitnessObjective, params = {})
    # We need to implement this since we have new parameters compared to the super class.
    super(fitnessObjective, DefaultParams.clone.update(params))
    @candidates = []
  end

  def add_if_interesting(candidate)
    @candidates << candidate
    @objective.group_rank_candidates()
  end

  def info_about_all_candidates
    @candidates.map do |c| 
      h = @objective.quality_of(c).data_to_json_hash
      h["pos"] = 0 # No order among the non-dominated
      h["type"] = "Non-dominated"
    end
  end
end

end