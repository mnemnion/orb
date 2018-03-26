# Pegylator and the Node class


  Current grym has a nodule of undigested code in the =/peg= directory.
This is early 2015 era stuff, and is built somewhat blindly upon epnf as I
found it on the internet.


It needs a substantial refactor. 

## Grammar class

This has the verbs:

### Grammar / new(Grammar, g_func, meta_tables)

This takes a function, building and returning a grammar over it.


  - #params
    - Grammar :  The __call object
    - g_func  :  The function(_ENV) grammar
    - meta_tables :  A map of rule ids to metatables.  These should themsevles
             inherit from Node.


The constructor handles building the metatable stack so that the table it returns
works like a function over a string returning a Node. 


Also automated: If a string isn't provided in =meta_tables=, the Node metatable
is assigned. I also have some notes on the [[Node class][./node]].


## Node class

  Covered [[here][./node]]


## Forest class

  This is just an array of Nodes offering a familiar =select= etc interface.


These are the only classes which should exist once this is cleaned up. 
