require 'feldtruby/optimize'
require 'feldtruby/logger'
require 'feldtruby/json'

module FeldtRuby::Optimize

# And APTArchive keeps an unbounded set of solutions in an efficient manner
# so it can be used both during optimization and for representing the ultimate
# solutions found during an multi-objective optimization run.
class AdaptivePartioningTreeArchive
  # Arbitrary initial range max and min for each objective. Not important since
  # it can grow at the edges if needed.
  ValueRangeMax = 10.0
  ValueRangeMin = -ValueRangeMax

  # Node of the APT.
  class Node
    attr_accessor :type             # Can be :leaf, :branch or :inactive
    attr_reader   :value_range_min  # Array of values, per dimension, in the partition in the tree below (and including) this node.
    attr_reader   :value_range_max  # Array of values, per dimension, in the partition in the tree below (and including) this node.
    attr_accessor :objective_index  # Integer index to the objective determining branching from this node
    attr_reader   :solutions        # The solutions in this partition (if :leaf node).
    attr_accessor :density_value    # Number of points in the partition represented by this node divided by the value range.
    attr_reader   :parent           # Parent node in tree
    attr_reader   :children         # Child nodes in tree (if :Branch node)
    attr_reader   :archive          # Handle to archive we are part of

    def initialize(archive, parent = nil, valueRangeMin = nil, valueRangeMax = nil, children = nil)
      @archive = archive
      @children = children
      @parent = parent
      @type = children.nil? ? :inactive : :leaf
      @objective = archive.objective
      @value_range_min = valueRangeMin || ([ValueRangeMin] * @objective.num_goals)
      @value_range_max = valueRangeMax || ([ValueRangeMax] * @objective.num_goals)
      @solutions = []
      recalc_statistics()
    end

    # Return the number of solutions in the tree under (and including) this node.
    def num_solutions
      if @type == :leaf
        @solutions.length
      elsif @type == :branch
        @children.inject(0) {|c,s| s+c.num_solutions}
      else
        0
      end
    end

    # Sub-divide node so that it becomes a branch node.
    def sub_divide_partition
      @objective_index = dimension_with_largest_dispersion()
      @type = :branch
      solutions = sort_solutions_for_objective @solutions, @objective_index

      # Divide the current value range for the sub-dividing objective
      bf, num_solutions = archive.branch_factor, solutions.length
      group_sizes = [num_solutions / bf] * bf

      # Add the one missing candidate to the mid group if they could not be evenly split among the groups.
      group_sizes[group_sizes.length / 2] += 1 if (num_solutions % bf != 0)

      # Max of previous partition must be the current min.
      prev_max = @value_range_min[@objective_index]

      # Go through all the group sizes calculated above and create leafs for them.
      group_sizes.each do |size|
        value_range_max = @value_range_max.clone
        value_range_min = @value_range_min.clone

        value_range_min[@objective_index] = prev_max

        # If there are more solutions left we calc the midpoint and use as max for this group.
        # Since solutions were sorted above we can just calc the average and use as mid point.
        if solutions.length > size
          # New max value is mid points between solutions on border between this group and the next.
          prev_max = value_range_max[@objective_index] = (solutions[size-1] + solutions[size]) / 2.0
        end

        @children = Node.new archive, self, value_range_min, value_range_max, solutions.take(size)

        solutions = solutions.drop(size)
      end
    end

    # Select one point/solution from the partition represented by this node.
    def select
    end

    # Add to partition of this node and return true iff it was a non-dominated
    # solution that was actually added.
    def add_to_partition(solution)
      return false if @solutions.include?(solution)
      solutions_including_new = @solutions + [solution]
      #puts "solutions_including_new = #{solutions_including_new.inspect}"
      group_ranks = @objective.group_rank_candidates solutions_including_new
      #puts "group_ranks = #{group_ranks.inspect}"
      @solutions = group_ranks.first

      # Return true only if new solution was included in archive, i.e. it was in
      # non-dominated, first rank after group ranking.
      was_added = group_ranks.first.include?(solution)

      if @solutions.length > archive.partition_treshold
        sub_divide_partition()
      elsif was_added
        recalc_statistics
      end

      return was_added
    end

    # Return true iff the given objectiveValue is in the value range of this
    # node for the given objectiveIndex.
    def in_value_range?(objectiveIndex, objectiveValue)
      (@value_range_min[objectiveIndex] <= objectiveValue) && 
        (objectiveValue <= @value_range_max[objectiveIndex])
    end

    def add_solution_with_quality(solution, qualityOfSolution)
      if @type == :leaf
        add_to_partition(solution)
      elsif @type == :branch
        objective_value = qualityOfSolution[@objective_index]
        update_value_range objective_value
        @children.each do |child|
          if child.in_value_range?(@objective_index, objective_value)
            if child.add_solution_with_quality(solution, qualityOfSolution)
              recalc_statistics
              return true
            else
              return false
            end
          end
        end
        # If we come here it was not added to archive so return false.
        return false
      else # So the type is :inactive and we must create a partition of it since we need to store a solution
        @type = :leaf
        @solutions = [solution]
        recalc_statistics()
        return true # Since solutions was added
      end
    end

    # Update the value range based on a new objective value for the objective
    # we branch on on this node.
    def update_value_range(valueForObjective)
      if valueForObjective < @value_range_min[@objective_index]
        @value_range_min[@objective_index] = valueForObjective
        @children.first.update_value_range valueForObjective
      elsif valueForObjective > @value_range_max[@objective_index]
        @value_range_max[@objective_index] = valueForObjective
        @children.last.update_value_range valueForObjective
      end
    end

    private

    def recalc_statistics
    end

    # Find the dimension with the largest dispersion of fitness values.
    def dimension_with_largest_dispersion()
    end
  end

  attr_reader :objective, :root, :branch_factor, :partition_treshold

  def initialize(objective, branchFactor = 2, partitionTreshold = 10)
    @objective = objective
    @branch_factor = 2
    @partition_treshold = 10
    @root = Node.new(self)
  end

  # Add a solution to the archive if it is non-dominated. Returns true iff
  # the solution was added.
  def add_solution(solution)
    add_solution_with_quality solution, @objective.quality_of(solution)
  end

  private

  def add_solution_with_quality(solution, qualityOfSolution)
    @root.add_solution_with_quality solution, qualityOfSolution
  end
end

end