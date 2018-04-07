
------
1. TOC
{:toc}
------

# Source maps

Link mania:


https:/_blogs.msdn.microsoft.com_davidni_2016_03_14_source-maps-under-the-hood-vlq-base64-and-yoda/


https:/_www.html5rocks.com_en_tutorials_developertools_sourcemaps_


http:/_murzwin.com_base64vlq.html


http:/_sokra.github.io_source-map-visualization/#simple-coffee


### Roadmap

First we need to actually nail down lines and offsets in the various classes.


That's going to be some exacting and chasey code.  Good behavior now will pay off
later. 


Once the classes all behave as promised, pushing out an in-memory source map
is relatively straightforward.  We traverse a doc building a string, so we 
have the information readily at hand and just need to pass it along.


Turning it into crazypants encoded offset format is the step after that. 


We can make good use of the not wacky version.
