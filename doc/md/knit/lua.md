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
