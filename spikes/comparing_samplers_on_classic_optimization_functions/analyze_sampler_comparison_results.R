#data <- read.csv("/Users/feldt/dev/feldtruby/spikes/results_comparing_samplers_levi13_beale_easom_eggholder.csv")

source("/Users/feldt/feldt/general/web/advice/statistics/nonparametric_effect_sizes.r")

data <- read.csv("/Users/feldt/dev/feldtruby/spikes/comparing_samplers_on_classic_optimization_functions/results_comparing_samplers_levi13_beale_easom_eggholder_all_radii_4_to_30.csv")
#data <- read.csv("/Users/feldt/dev/feldtruby/spikes/comparing_samplers_on_classic_optimization_functions/results_comparing_samplers_omnitest.csv")
data2 <- read.csv("/Users/feldt/dev/feldtruby/spikes/comparing_samplers_on_classic_optimization_functions/results_comparing_samplers_130405_175934.csv")

# Combine Sampler and Radius into one column and use shorter name for Sampler.
data$SamplerRadius <- sapply(data, function(x) paste(ifelse(data$Sampler=="PopulationSampler", "PS", "RL"), data$Radius, sep=""))[,1] 
data2$SamplerRadius <- sapply(data2, function(x) paste(ifelse(data2$Sampler=="PopulationSampler", "PS", "RL"), data2$Radius, sep=""))[,1] 

# Select only columns we need
d <- subset(data, select = c(Problem, SamplerRadius, Q, NumSteps))
d2 <- subset(data2, select = c(Problem, SamplerRadius, Q, NumSteps))

print_mean_per_sampler <- function(d, numsteps) {
  for(p in levels(unique(d$Problem))) {
    ds <- subset(d, Problem == p & NumSteps == numsteps)

    cat("Problem = ", p, "\n");
    print(aggregate(. ~ SamplerRadius, ds, mean));
    cat("\n");
  }
}

library(ggplot2)

pwt <- function(data, problem, numsteps) {
  d <- subset(data, Problem == problem & NumSteps == numsteps)
  d$SamplerRadius <- with(d, reorder(SamplerRadius, Q, median))
  with(d, pairwise.wilcox.test(Q, SamplerRadius))
}

boxplot_numsteps_problem <- function(data, problem, numsteps) {
  d <- subset(data, Problem == problem & NumSteps == numsteps)
  d$SamplerRadius <- with(d, reorder(SamplerRadius, Q, median))
  print(pwt(data, problem, numsteps))
  p <- ggplot(d, aes(SamplerRadius, Q))
  p + geom_boxplot()
}

effect.size <- function(data, problem, numsteps, sr1, sr2) {
  d <- subset(data, Problem == problem & NumSteps == numsteps)
  d$SamplerRadius <- with(d, reorder(SamplerRadius, Q, median))
  d1 <- subset(d, SamplerRadius == sr1)
  d2 <- subset(d, SamplerRadius == sr2)
  a.statistic(d1$Q, d2$Q)  
}

boxplot_numsteps_problem(d, "MinLeviFunctionNum13", 1000)
boxplot_numsteps_problem(d, "MinLeviFunctionNum13", 5000)
boxplot_numsteps_problem(d, "MinLeviFunctionNum13", 10000)
boxplot_numsteps_problem(d, "MinLeviFunctionNum13", 25000)
boxplot_numsteps_problem(d, "MinLeviFunctionNum13", 50000)
print_mean_per_sampler(d, 10000)

boxplot_numsteps_problem(d, "MinBealeFunction", 1000)
boxplot_numsteps_problem(d, "MinBealeFunction", 5000)
boxplot_numsteps_problem(d, "MinBealeFunction", 10000)
boxplot_numsteps_problem(d, "MinBealeFunction", 25000)
boxplot_numsteps_problem(d, "MinBealeFunction", 50000)
effect.size(d, "MinBealeFunction", 50000, "RL4", "RL5")

boxplot_numsteps_problem(d, "MinEasomFunction", 1000)
boxplot_numsteps_problem(d, "MinEasomFunction", 5000)
boxplot_numsteps_problem(d, "MinEasomFunction", 10000)
boxplot_numsteps_problem(d, "MinEasomFunction", 25000)
boxplot_numsteps_problem(d, "MinEasomFunction", 50000)

boxplot_numsteps_problem(d, "MinEggHolderFunction", 1000)
boxplot_numsteps_problem(d, "MinEggHolderFunction", 5000)
boxplot_numsteps_problem(d, "MinEggHolderFunction", 10000)
boxplot_numsteps_problem(d, "MinEggHolderFunction", 25000)
boxplot_numsteps_problem(d, "MinEggHolderFunction", 50000)

boxplot_numsteps_problem(d, "MinOmniTest", 25000)
effect.size(d, "MinOmniTest", 50000, "RL5", "PS15")
