module FeldtRuby::Optimize

  # A mutator mutates candidates.
  class Mutator
  end

  class VectorMutator < Mutator
    attr_reader :search_space

    def initialize(optimizer, valueMutator = GaussianContinuousValueMutator.new)
      @optimizer = optimizer
      @search_space = optimizer.search_space
      @value_mutator = valueMutator
      @value_mutator.mutator = self
    end

    # Mutate a candidate and returned a mutated vector.
    def mutate(candidate)
      c = candidate.clone
      index = rand(candidate.length)
      c[index] = @value_mutator.mutate_value(value, index)
      @search_space.bound_at_index(c, index)
    end
  end

  # Random Gaussian variates from:
  #  http://stackoverflow.com/questions/5825680/code-to-generate-gaussian-normally-distributed-random-numbers-in-ruby
  class RandomGaussian
    def initialize(mean = 0.0, sd = 1.0)
      @mean, @sd = mean, sd
      @compute_next_pair = false
    end
  
    def sample
      if (@compute_next_pair = !@compute_next_pair)
        # Compute a pair of random values with normal distribution.
        # See http://en.wikipedia.org/wiki/Box-Muller_transform
        theta = 2 * Math::PI * rand()
        scale = @sd * Math.sqrt(-2 * Math.log(1 - rand()))
        @g1 = @mean + scale * Math.sin(theta)
        @g0 = @mean + scale * Math.cos(theta)
      else
        @g1
      end
    end
  end

  # This will mutate with a gaussian sample of mean which is half the delta
  # for the variable being mutated.
  class GaussianContinuousValueMutator
    def initialize
      @gaussian = RandomGaussian.new(0.0, 1.0)
    end

    # Connect with the value mutator, calculate bounds etc.
    def mutator=(mutator)
      @mutator = mutator
      @deltas = @mutator.search_space.deltas
    end

    def mutate_value_at_index(value, index)
      sigma = @deltas[index]/2.0
      value + (sigma * @gaussian.sample)
    end
  end

  # A Stochastic Hill Climber will randomly mutate one variable of the candidate
  # and then keep the new candidate if it was better.
  class StochasticHillClimber < SingleCandidateOptimizer
    DefaultOptions = {
      :mutatorClass => 
    }

    def initialize_options(options)
      super
      @options = DefaultOptions.clone.update(options)
      @mutator = @options[:mutatorClass].new(self)
      @candidate = @search_space.gen_candidate
    end

    def optimization_step
      [@mutator.mutate(@candidate), @candidate]
    end
  end

end
