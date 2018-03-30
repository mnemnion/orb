# Extended Lpeg module


  This is where we add extended captures a la the old =epeg= 
module.


The difference here is that we include lpeg as a metatable __index
and can therefore use elpeg as L everywhere we currently use lpeg.

```lua
local lpeg = require "lpeg"
local epeg = setmetatable({}, {__index = lpeg})

```
## Ppt -- Codepoint pattern

Captures one Unicode point


I actually have no idea how to do this yet...


Looks like byte 97 is just =\97= in Lua. That's easy enough.

```lua
local function num_bytes(str)
--returns the number of bytes in the next character in str
   local c = str:byte(1)
   if c >= 0x00 and c <= 0x7F then
      return 1
   elseif c >= 0xC2 and c <= 0xDF then
      return 2
   elseif c >= 0xE0 and c <= 0xEF then
      return 3
   elseif c >= 0xF0 and c <= 0xF4 then
      return 4
   end
end
```
## Csp -- Capture span

This is the old-school capture that plays into making named Nodes using
epnf.

```lua
local function spanner(first, last, str, root)
   local vals = {}
   vals.span = true
   vals.val = string.sub(str, first, last - 1)
   vals.first = first
   vals.last = last - 1
   if vals.last >= vals.first then
      return vals
   end
   -- If a capture contains nothing, we don't want a node for it
   return nil
end

function epeg.Csp (patt)
   return lpeg.Cp() 
      * lpeg.Cmt(patt, function() return true end) 
      * lpeg.Cp() 
      * lpeg.Carg(1) 
      * lpeg.Carg(2) / spanner
end
```
```lua
return epeg
```
