# C


  With this addition, Orb finally stretches its legs, and strides forth as a
true polyglot programming language\.

Our current codeblock flavors are Lua, SQL, and PEG\.  But we have no knitters
for SQL and PEG, and we probably won't: they aren't programming languages, in
and of themselves\.

If we include the 
\#asLua
 hashtag, and we normally do, they compile into
Lua long strings\.  This is a nice affordance: we get syntax highlighting,
thereby avoiding the "inner language" effect where any dialect which isn't the
runtime environment has to be treated as a string\.

Also, and this will prove useful for SQL\(ite\) in particular, we can reuse the
codeblocks in other contexts\.  SQLite doesn't care which language you're
calling it from, and we can transclude SQL blocks into another language\.\.\.
once we have a\) transclusion, and b\) other languages\.

Which brings us to C\.  We will have an 
\#asLua
 form for the C language,
which will call `ffi.cdef[[...]]` on the codeblock, so we can have nice syntax
highlighting for the FFI\.  But that's a function proper to the Lua knitter,
and this is the C knitter\.  We're going to special\-case the C knitter to
ignore these, and come up with a general solution as we go\.

Our runtime is written in C, and is the only internal piece of code which
isn't written in Orb\.  It's time to change that, so we need a C knitter\.

#### Interface

A knitter must expose these fields:


- code\_type:  A string corresponding to the `code-type` field of a Doc\.
    E\.g\. `lua` for Lua source code\.

    This should probably be


- pred:  A function to determine if a non\-code\_type code block
    should be parsed by the knitter\.  Must return `true` or
    `false`\.

  - params:

    - codeblock:  A Node of class codeblock\.


- knit:  A function to knit an ordinary codeblock of type `code_type`

   - params:

     - codeblock:  A Node of class codeblock\.

     - scroll:  The scroll in which the knit is to be inserted\.

     - skein:  The skein, holding all additional state, such as the original
         Doc, file paths, and so on\.


- knit\_pred:  A function to knit a codeblock matching the predicate\.  Same
    parameters as `knit`\.


#### imports

We use the predicator to ignore 
\#asLua
 blocks:

```lua
local c_noknit = require "orb:knit/predicator" "#asLua"
```


## C Knitter

```lua
local c_knit = {}
```


### Code type

```lua
c_knit.code_type = "c"
```


### Predicate

```lua
c_knit.pred = function() return false end
```


### Knitter


```lua
function c_knit.knit(codeblock, scroll, skein)
   if c_noknit(codeblock) then return end
   local codebody = codeblock :select "code_body" ()
   local line_start, _ , line_end, _ = codebody:linePos()
   for i = scroll.line_count, line_start - 1 do
      scroll:add "\n"
   end
   scroll:add(codebody)
   -- add an extra line and skip 2, to get a newline at EOF
   scroll:add "\n"
   scroll.line_count = line_end + 2
end
```
