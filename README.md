feldtruby
=========
Robert Feldt's Common Ruby Code lib. I will gradually collect the many generally useful Ruby tidbits I have laying around and clean them up into here. Don't want to rewrite these things again and again... So far this collects a number of generally useful additions to the standard Ruby classes/libs and then includes a simple optimization framework (FeldtRuby::Optimize).

Note that good documentation is not really a focus here. As things mature in here I will move logically unique/separate sets of functionality into separate Ruby libs/gems of useful code. At that point there will be more focus on documentation.

email: robert.feldt ((a)) gmail.com

Contents
--------

### Statistics
* Cluster linkage metrics
* Access to R from Ruby (extends existing lib so that you can more easily transfer complex objects back to Ruby)
* ...

### Time
	Time.timestamp()    				# Get a timestamp string back with the current time

### Array

Basic calc/statistics: sum, mean, average, stdev, variance, rms, weighted_sum, weighted_mean,
sum_of_abs, sum_of_abs_deviations

	[1,2,3].swap!(0,2) 					=> [3, 2, 1] # destructive swap of two elements
	[1,2,5].distance_between_elements 	=> [1, 3]
    [15, 1, 7, 0].ranks					=> [1, 3, 2, 0]
    [[2.3, :a], [1.7, :b]].ranks_by {|v| v[0]}	=> [[1, 2.3, :a], [2, 1.7, :b]]

### Float
	1.456.round_to_decimals(2) 			=> 1.46 (round to given num of decimals)

### FileChangeWatcher
Watch for file changes in given paths then call hooks with the updated files.

### Kernel
	rand_int(top)	 					# random integer in range 0...top

### Optimize
A simple optimization framework with classes:

* Objective				(single or multi-objective optimization critera)
* SearchSpace			(capture constraints for optimization values/parameters)
* RandomSearcher 		(random search for optimal values)
* DifferentialEvolution	(effective numerical optimization with evolutionary algorithm)

but also support for different type of logging etc. Setting up an optimization can
be quite involved but there is a simple wrapper method, with good defaults, for
numerical optimization using DE:

	# Optimizing with the Rosenbrock function on [0, 2], see:
	# 	http://en.wikipedia.org/wiki/Rosenbrock_function
	require 'feldtruby/optimize'
	xbest, ybest = FeldtRuby::Optimize.optimize(0, 2) {|x, y|
		(1 - x)**2 + 100*(y - x*x)**2
	}

Copyright
------------
Copyright (c) 2012-2013 Robert Feldt. See LICENSE.txt for
further details.