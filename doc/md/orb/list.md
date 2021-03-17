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


### Implementation

  This one is a bit trickier than folding sections, but it's the same basic
operation\.

Each deeper level of indentation belongs to the next\-lowest section which is
above it in the heirarchy\.

All of the list lines start under the top list, and all but the first run of
top\-level list lines get moved, followed by `compact`ing the top list\.

The Doc case is simpler, because we aren't creating anything\.  Everything at
the top level is either a block, or a Section with no Section above it:
usually, but not inevitably, a `*` Section\.

For Lists, we do have to create a new List out of the List\-line **before** a
deeper List\-line, replace it with that List, and then put subsequent
List\-Lines underneath it\.

Doesn't really change anything, we end up with the top\-level List having holes
in it and `compact` will fix those, while the sub\-Lists are all created on the
fly and don't require further attention\.


#### imports

```lua
local Twig = require "orb:orb/metas/twig"
local table = require "core:core/table"
local anterm = require "anterm:anterm"
local c = require "singletons/color" . color -- #todo remove

local s = require "status:status" ()
s.verbose = false
```


## List Metatable

```lua
local List = Twig :inherit 'list'

local super_strExtra = Twig . strExtra

function List.strExtra(list)
   local phrase = super_strExtra(list)
   return phrase .. anterm.magenta(tostring(list.indent))
end
```


### Post\-processing

A wickedly complex state machine\.

In retrospect, this would have been simpler to write by not treating the base
list as special, and instead allocating a new list to represent it\.

There are a number of logic branches to accomodate this, and it took me
several hours to identify various places where I was doing the wrong thing\.

As of this commit, it *appears* to be behaving correctly, and it's not quite
worth it to me to rewrite it cleaner\.  I may change my mind, however; I could
pretend that avoiding one \(1\) extra table allocation per list is 'better' in
some sense, but it simply isn't\.

This commit contains all the debugging info I used to isolate the problem, but
I will remove them in the next one, along with this paragraph\. An uncalled
status print is quite cheap, but this is so much detail that it hides the
algorithm, and our `:linePos()` has worse complexity than it should\.


#### What does it do though

This iterates over all the lines of the list, which begins 'flat'\.

If it finds an indentation greater than that of the working list, which, to
begin with, is just the list, then it creates a sublist\.  I decided that
sublists just have the `id` 'list', but that the line previous to the indented
part is a special part of the sublist, with `id` 'lead'\.

This accounts for a lot of what made this algorithm annoying\.  But it leaves
us with the nice property that a list of a given indentation will contain only
lines, and lists which have one line of the same indentation in the 'lead'
position\.  The alternative means that a list with three lines, one of which
contains a sublist, has four children, and two of the siblings have a logical
relationship which is expressed only through proximity\.

The incidental complexity arises from my deciding to keep the base list,
instead of just building a new list\.  Thus we must `nil` out moved lines, but
leave lines proper to the base list in place, `compact`ing at the end\.

Since constructing a sublist require retrieving the prior line, then replacing
it with the sublist, this also calls for two code paths to do the same thing\.

There is also the non\-trivial matter of constructing new Nodes manually, while
keeping the `.last` field of parent lists correct\.  This is essential
complexity, but I will confess that a type system might have assisted here\.

I did add a couple more checks to `Node:validate()`, the poor man's runtime
type system, and it did help\.

Be that as it may, the result is fit to purpose, and returned by the List\_fn
metafunction as a new Node of the appropriate shape\.

```lua
local DEPTH = 20
local function _parent(list, dent, list_line)
   s:verb("list_line @ line %d", list_line:linePos())
   s:verb("indent is %d", dent)
   local parent = list
   local count = 1
   repeat
      s:verb("list @ line %d", parent:linePos())
      s:verb("list %s", parent:strLine(c))
      parent = parent.parent
      s:verb("parent @ line %d", parent:linePos())
      s:verb("parent %s", parent:strLine(c))
      count = count + 1
   until parent.indent <= dent or count == DEPTH
   if count >= DEPTH then
      s:verb(anterm.red("infinite loop averted in _parent"))
      s:verb(debug.traceback())
   end
   return parent
end
```

```lua
local function _makesublist(parent, line)
   local linestart, _, linend = parent:linePos()
   s:verb("making a sublist of list @ %d to %d, %s",
           linestart, linend, parent:strLine(c))
   if not line then
      s:verb("no line! \n %s", debug.traceback())
   end
   linestart, _, linend = line:linePos()
   s:verb("adding line @ lines %d to %d, %s", linestart, linend, line:strLine(c))
   local sublist = { first = line.first,
                     last = line.last,
                     parent = parent,
                     str = line.str }
   local lead = { first = line.first,
                  last = line.last,
                  parent = sublist,
                  str = line.str,
                  id = 'lead' }
   setmetatable(lead, Twig)
   sublist[1] = lead
   lead[1] =  line
   line.parent = lead
   return setmetatable(sublist, List)
end
```

```lua
local insert, compact = assert(table.insert), assert(table.compact)

local function _insert(list, list_line)
   local listart = list:linePos()
   local linstart = list_line:linePos()
   s:verb("inserting line %d: %s", linstart, list_line:strLine(c))
   s:verb("into list %d: %s", listart, list:strLine(c))
   insert(list, list_line)
   list_line.parent = list
   list.last = list_line.last
   -- the base list won't have a parent yet
   if not list.parent then return end
   local parent = list.parent
   while parent.parent and parent.id == 'list' do
      parent.last = list_line.last
      local newparent = parent.parent
      parent = newparent
   end
   --]]
end

local function post(list)
   local linum = list:linePos()
   s:verb("starting list at line %d", linum)
   local top = #list
   local base = list[1].indent
   -- add an indent to the list itself

   list.indent = base
   -- tracking variables:
   local dent = base
   local work_list = list
   for i = 1, top do
      -- is it an indent line?
      if not list[i].indent then
         local id, line, col = list[i].id, list[i]:linePos()
         s:verb("no indent on %s at line %d, col %d", id, line, col)
      end
      if list[i].indent > dent then
         -- handle base list a bit differently
         if work_list == list then
            s:verb("list[i].indent > dent and work_list is base")
            -- make a list from the previous line
            local sublist = _makesublist(work_list, list[i - 1])
            dent = list[i].indent
            sublist.indent = dent
            -- insert working line
            _insert(sublist, list[i])
            -- replace prior line with list
            list[i - 1] = sublist
            -- nil out working line
            list[i] = nil
            -- replace the work list
            work_list = sublist
         else
            s:verb("list[i].indent > dent and worklist ~= base")
            local sublist = _makesublist(work_list, work_list[#work_list])
            -- this moves the tip of the work list to the lead of the sub list
            -- so we need to remove it from the work list
            work_list[#work_list] = nil
            dent = list[i].indent
            sublist.indent = dent
            _insert(work_list, sublist)
            _insert(sublist, list[i])
            list[i] = nil
            work_list = sublist
         end
      elseif dent > base and dent == list[i].indent then
         -- put it in the worklist
         s:verb("dent > base and dent == list[i].indent")
         _insert(work_list, list[i])
         list[i] = nil
      elseif list[i].indent < dent then
         s:verb("list[i].indent < dent")
         -- get a new work_list
         work_list = _parent(work_list, list[i].indent, list[i])
         if work_list ~= list then
            _insert(work_list, list[i])
            list[i] = nil
         else
            -- just reporting, we don't need to do anything
            local linstart = list[i]:linePos()
            s:verb("leaving line %d in place: %s", linstart, list[i]:strLine(c))
         end
         dent = list[i].indent

      else -- otherwise we have a list_line we can leave in place
         local linstart = list[i]:linePos()
         s:verb("leaving line %d in place: %s", linstart, list[i]:strLine(c))
      end
   end
   compact(list, top)
   s:verb("completed list at line %d", linum)
   return list
end
```


### List Function

  We could make a subgrammar and use this as a proper post function, but
there's not a lot of point in doing so, since we don't have additional grammar
to match\.

So this is just a function which performs the folding on the list and returns
it\.

```lua
local function List_fn(list, offset)
   setmetatable(list, List)
   return post(list)
end
```

```lua
return List_fn
```
