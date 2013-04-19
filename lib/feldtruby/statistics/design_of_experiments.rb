module FeldtRuby::Statistics

# Functions for designing parameter exploration experiments using Bayesian
# Treed Gaussian Process models.
#
# Parameters are assumed to be given in a hash, mapping a parameter name to its
# range of allowed values, like:
#
#   IndependenVars = {
#     :PopulationSize => [5, 500],
#     :PopulationSamplerRadius => [4, 500], # must actually be smaller than the population size or it makes no difference, how to spec such constraints?
#     :F => [0.0, 1.0],
#     :CR => [0.0, 1.0],
#     :numEvals => [1e3, 1e5] # Or should we vary this for each setting of the others and just measure the outputs at several points of numEvals?
#   }
#
#   DependentVars = {
#     Y1 = # execution_time for running the algorithm
#     Y2 = # best model RMS error
#   }
module DesignOfExperiments
  # Do a latin hypercube sampling of the parameter space with bouding box per 
  # parameter specified in _parameters_.
  def latin_hypercube_sample_of_parameters(parameters, numSamples)
    include_library("tgp")
    param_order = parameters.keys.sort
    script = <<-EOS
      params <- #{parameters_to_R_data_frame(parameters, param_order)};
      x_candidates <- lhs(#{numSamples}, params);
    EOS
    subst_eval script, {}
    pull_matrix_variable_to_hash_with_column_names "x_candidates", param_order
  end

  def parameters_to_R_data_frame(parameters, param_order = parameter.keys)
    s = param_order.map do |p|
      lim = parameters[p]
      "c(#{lim[0]}, #{lim[1]})"
    end.join(", ")
    "rbind(#{s})"
  end
end

end

class FeldtRuby::RCommunicator
  include FeldtRuby::Statistics::DesignOfExperiments
end
