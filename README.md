Kefka (Experimental)
====

A tool for understanding unfamiliar codebases and 3rd party libraries. Basic Idea is to visualize the method callgraph of a program while showing local variable values for each line of execution.

![http://i.imgur.com/591Wz.png](http://i.imgur.com/591Wz.png)

Installation
----

    $ gem install kefka

Usage
----

    $ kefka
    Go to browser and point to http://localhost:4567/

TODO
----

show multiple locals values in loops/recursive calls/methods called from different sources
better UI
visualize links ( line call to a method )

Related Papers
----

http://relo.csail.mit.edu/documentation/relo-vlhcc06.pdf
http://dmrussell.net/CHI2010/docs/p2503.pdf

Contributing to kefka
----

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

== Copyright

Copyright (c) 2012 Reginald Tan. See LICENSE.txt for
further details.

