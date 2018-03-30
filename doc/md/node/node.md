# Node


  Time to stabilize this class once and for all. 


## Node metatable

  The Node metatable is the root table for any Node.  I'm planning to make
an intermediate class/table called Root that is in common for any instance
Node.  All it absolutely has to contain is =str=. 


### Fields

   - id :  A string naming the Node. 
           This is identical to the name of the pattern that recognizes
           or captures it.
   - line_first :  Always -1.
   - line_last  :  Always -1. 


## Node Instances

  To be a Node, currently, indexed elements of the Array portion must also be 
Nodes. 


I'm mostly convinced that indexed elements can also be strings, and that 
this is the form leaf nodes should take.  Currently, they have a 'val' field
and no children, which we should replace with a child string at [1].


This gives us a lighter way to handle the circumstance where we have, say,
a list, =(foo bar baz)=. We currently either need a "left-per" or "pal"
Node class to hold the =(=, or we would have to skip it entirely.


Quipu can't lose any information from the string, so they have to include
whitespace.  We're not limited in the same way and can reconstruct less 
semantically crucial parts of a document using the span and the original 
string, since we're not /currently/ editing our strings once they're
entered in.


Nodes are meant to be broadly compatible with everything we intend to
do with abstract syntax trees.  The more I think about this the better
it strikes me as an approach. 


### Fields

  There are invariant fields a Node is also expected to have, they are:
 
  - first :  Index into =str= which begins the span.
  - last  :  Index into =str= which ends the span.


In principle, we want the Node to be localized. We could include a 
reference to the whole =str= and derive substrings lazily.


If we included the full span as a substring on each Node, we'd end up
with a lot of spans, and wouldn't use most of them. Even slicing a piece
out is costly if we're not going to use it. 


So our constructor for a Node class takes (Constructor, node, str) as 
the standard interface.  If a module needs a non-standard constructor,
as our Section and Block modules currently take an array of lines, that
will need to be provided as the second return from the module. 


This will allow for the kind of multi-pass recursive-descent that I'm
aiming for. 


#### line tracking (optional)

It may be wise to always track lines, in which case we will include:


  - line_first :  The line at which the match begins
  - line_last  :  The line at which the match ends


This is, at least, a frequent enough pattern that the metatable should return
a negative number if these aren't assigned. 


- [ ] #todo decide if line tracking is in fact optional


### Other fields

  The way the Grammar class will work: each =V"patt"= can have a metatable.
These are passed in as the second parameter during construction, with the key
the same name as the rule. 


If a pattern doesn't have a metatable, it's given a Node class and consists of
only the above fields, plus an array representing any subrules. 


If it does, the metatable will have a =__call= method, which expects two
parameters, itself, and the node, which will include the span. 


This will require reattunement of basically every class in the =/grym= folder,
but let's build the Prose parse first.  I do want the whole shebang in a single
grammar eventually.


The intention is to allow multiple grammars to coexist peacefully. Currently
the parser is handrolled and we have special case values for everything.
The idea is to stabilize this, so that multi-pass parsing works but in a
standard way where the Node constructor is a consistent interface. 


In the meantime we have things like


- lines :  If this exists, there's a collection of lines which need to be
           joined with =\n= to reconstruct the actual span.


           We want to do this the other way, and use the span itself for the
           inner parse. 

```lua
assert(true)
return {}
```
