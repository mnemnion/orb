# Node class

## THIS FILE IS DEPRECATED

  The behavior of abstract syntax trees in pegylator is provided by the Node
class.


This is in turn poorly specified and full of exploratory code that is in need
of a few once-overs.


## Members


  To be a Node, all indexed elements of the Array must also be Nodes. 


There are invariant fields a Node is also expected to have, they are:
 
  - first :  Index into str which begins the span.
  - last  :  Index into str which ends the span.
  - id    :  A string naming the Node. 
               This is identical to the name of the pattern that recognizes
               or captures it.



There are other fields which are of less obvious value, which still exist:


  - str  : a "string" covering the whole abstract syntax tree.
             This is normally found on root for which see:
  - root : a function which, called, returns the root node.
             I was impressed with this idea when I came up with it.
             Haven't been getting much use out of it.


An important optional field, if a Node has a semantic span (such as a symbol)
then it will have:


  - val :  The substring of value to the syntax tree.


## Node metatable


  This is currently constructed wildly and piecemeal.  It also does important
work. 


Best methods are:


### dot

  Some of my most recent code, this prints the AST as a dot file. 


It is now reasonably documented in [[src/peg/transform.lua]].


### select

  Select pulls out sub Nodes which fulfill certain predicates.


