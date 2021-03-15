# List


  A subgrammar for lists, which orders them arcically\.


### Structure

The list and listline rules are concerned with capturing a full list, which is
mainly a matter of detecting indentations and recognizing the lead sequences
which produce a new line\.  There is a listline subrule to handle the details
of parsing within a list line\.

This gives us a flat structure, for which we calculate the indentation of each
line; but for various operations, we want an arcical structure, a tree\.

The question is, which structure? For a list like this:

```orb
-  A list item
-  A sublist:
   -  a
   -  b
```

We could represent this as `{List = {Line, Line, List = {Line, Line}}}`, but
the second top\-level line is properly associated with the sub\-list\.  Various
operations we will perform depend on this, and we don't want to have to
extract it from context\.

So the List metatable will post\-process so that the Node looks like this:

```orb
-  list
  -  list_line
  -  list
    -  lead
      -  list_line
    -  list_line
    -  list_line
```

This means that the top\-level has only two items, not three, and the bottom
level has three items, but one is 'special', so it has two ordinary items,
which is basically correct\.




```lua
local subgrammar = require "espalier:espalier/subgrammar"
local Twig = require "orb:orb/metas/twig"
```

```lua
local list_str = [[
     list
]]
```
