# Lua knitter


 Our workhorse.


Knitters are provided as a simple table with a common format.


We may want to add a base class at some point, if it proves necessary.

```lua
local lua_knit = {}
```
### code_type

A knitter is always applied if the ``code_type`` field of the ``codeblock``
matches this string.

```lua
lua_knit.code_type = "lua"
```
### lua_knit.pred(codeblock)

A ``pred``icate function which determines whether to apply the knitter if the
``code_type`` is something else.

```lua
function lua_knit.pred(codeblock)
   local should_knit = false
   for tag in codeblock:select "hashtag" do
      if tag:span() == "#asLua" then
         should_knit = true
      end
   end

   return shoud_knit
end
```
### lua_knit.knit(codeblock, scroll)

For knitting under standard conditions.


Adds contents to the ``scroll``, no return value.

```lua
function lua_knit.knit(codeblock, scroll)
   -- add one line for the header
   -- #todo add the linepos for header and footer
   scroll:add "\n"
   -- add the codeblock contents
   -- #todo add as Node
   scroll:add(codeblock:select("code_body")():span())
   -- add another line for the footer
   scroll:add "\n"
end
```
### lua_knit.pred_knit(codeblock, scroll)

For knitting a matched predicate.


This function can be almost arbitrarily complex, but a simple pattern will get
us started: ignore the type of the codeblock, and make it into a Lua string.


The next stage will be to incorporate C by calling ``ffi.cdef``.  With
tranclusion, we can do some pretty remarkable things this way.

```lua
function lua_knit.pred_knit(codeblock, scroll)
   local name = codeblock:select "name"
   if name then
      name = name:select "handle" :span() :sub(2)
      -- #todo verify/coerce valid Lua symbol
      -- #todo look for =.=, modify header if found
   else
      -- #todo complain about this
      return
   end
   local header = "local " .. name .. " = [["
   scroll:add(header)
   scroll:add(codeblock:select("code_body")():span())
   scroll: add "]]"
   -- #todo search for =="]" "="* "]"== in code_body span and add more = if
   -- needful
end
```
```lua
return lua_knit
```
