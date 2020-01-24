# Codeblock


  Inner parser for code blocks.


This is a good example of how we can extract different syntactic information
at different levels.


For example: we know that the last line will be a ``code-end``, so we don't have
to detect a matching number of ``!`` and ``/``, and we don't have to check that
the closing line is flush with the margin, only that it's the final non-blank
line in the block.

```lua
local Peg = require "espalier:espalier/peg"
local Node = require "espalier:espalier/node" -- shouldn't need this long term
```
```lua
local code_str = [[
    codeblock  ←  code-start code-body code-end
   code-start  ←  "#" "!"+ code-type* (!"\n" 1)* "\n"
    code-body  ←  (!code-end 1)+
     code-end  ←  "#" "/"+ code-type*  (!"\n" 1)* line-end
    code-type  ←  (([a-z]/[A-Z]) ([a-z]/[A-Z]/[0-9]/"-"/"_")*)
   `line-end`  ←  ("\n\n" "\n"* / "\n")* (-1)
]]
```
```lua
local code_peg = Peg(code_str)
```
```lua
local function Code(t)
   local match = code_peg(t.str, t.first, t.last)
   if not match then
      t.id = "code-nomatch"
      return setmetatable(t, Node)
   end
   return match
end
```
```lua
return Code
```
