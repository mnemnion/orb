# Header


```lua
local Peg = require "espalier:espalier/peg"
```
```lua
local header_str = [[
     header  <-  level head-line
      level  <-  "*"+
  head-line  <-  (" " header-text) / -1
  header-text <- 1*
]]
```
```lua
local header_grammar = Peg(header_str)
```
```lua
local Header = function(t)
   assert(type(t.str) == "string")
   assert(type(t.first) == "number")
   assert(type(t.last) == "number")
   local match = header_grammar(t.str, t.first, t.last)
   return match
end
```
```lua
return Header
```
