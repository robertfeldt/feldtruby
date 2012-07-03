feldtruby
=========
Robert Feldt's Common Ruby Code lib. I will gradually collect the many generally useful Ruby tidbits I have laying around and clean them up into here. Don't want to rewrite these things again and again... So far this collects a number of generally useful additions to the standard Ruby classes/libs and then includes a simple optimization framework (FeldtRuby::Optimize).

email: robert.feldt ((a)) gmail.com

Contents
--------
### Time
	Time.timestamp()    				# Get a timestamp string back with the current time

### Array

Basic calc/statistics: sum, mean, average, stdev, variance, rms, weighted_sum, weighted_mean

	[1,2,3].swap!(0,2) 					=> [3, 2, 1] # destructive swap of two elements
	[1,2,5].distance_between_elements 	=> [1, 3]

### Float
	1.456.round_to_decimals(2) 			=> 1.46 (round to given num of decimals)

### FileChangeWatcher
Watch for file changes in given paths then call hooks with the updated files.

### Kernel
	rand_int(top)	 					# random integer in range 0...top

### Optimize
* Objective				(single or multi-objective optimization critera)
* SearchSpace			(capture constraints for optimization values/parameters)
* RandomSearcher 		(random search for optimal values)
* DifferentialEvolution	(effective numerical optimization with evolutionary algorithm)

Contributing to feldtruby
------------------------- 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
------------
Copyright (c) 2012 Robert Feldt. See LICENSE.txt for
further details.