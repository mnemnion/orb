# Code Block Module


   Code blocks are the motivating object for Grimoire.  Perforce they
 will do a lot of the heavy lifting.


 From the compiler's perspective, Code, Structure, and Prose are the
 three basic genres of Grimmorian text.  In this implementation,
 you may think of Code as a clade diverged early from both Structure
 and Prose, with some later convergence toward the former. 
 
 Specifically, Structure and Prose will actually inherit from Block, and
 Code block, name notwithstanding, merely imitates some behaviours.
 

## Fields


   Codeblock inherits from Node directly, and is born with these 
 additional fields:


 - level  :  The number of !s, which is the number of / needed to close
             the block.
 - header :  The line after # and at least one !.
 - footer :  The line closing the block. Optional, as a code block may
             end a file without a closing line.
 - lines  :  Array containing the lines of code.  Header and footer
             are not included.
 - line_first :  The first (header) line of the block. 
 - line_last  :  The closing line of the block. Note that code blocks also
                 collect blank lines and may have a clinging tag. 
 
 To be added:
 - [ ] lang : The language, derived from the header line.

```lua
local L = require "lpeg"

local Node = require "espalier/node"

local m = require "Orbit/morphemes"

local CB = setmetatable({}, Node)
CB.id = "codeblock"

CB.__index = CB

CB.__tostring = function() return "codeblock" end
```

 Adds a .val field which is the union of all lines.
 Useful in visualization. 

```lua
function CB.toValue(codeblock)
    codeblock.val = ""
    for _,v in ipairs(codeblock.lines) do
        codeblock.val = codeblock.val .. v .. "\n"
    end

    return codeblock.val
end

function CB.toMarkdown(codeblock)
  -- hardcode lua
  local lang = codeblock.lang or "orbdefault"
  return "```" .. lang .. "\n" 
         .. codeblock:toValue() .. "```\n"
end

function CB.dotLabel(codeblock)
    return "code block " .. tostring(codeblock.line_first)
        .. "-" .. tostring(codeblock.line_last)
end

local cb = {}
```
### asserts

```lua
function CB.check(codeblock)
  assert(codeblock.line_first)
  assert(codeblock.line_last)
end
```

 - #args
   - str :  The string to match against.
 
 - #return 3
   - boolean :  For header match
   - number  :  Level of header
   - string  :  Header stripped of left whitespace and tars


```lua
function cb.matchHead(str)
    if str ~= "" and L.match(m.codestart, str) then
        local trimmed = str:sub(L.match(m.WS * m.hax, str))
        local level = L.match(m.zaps, trimmed) - 1
        local bareline = trimmed:sub(L.match(m.zaps, trimmed))
        return true, level, bareline
    else 
        return false, 0, ""
    end
end
```

 Matches a code block footer line.


 - #args
   - str   :  The string to match against.
   - level :  Required level for a match.
 
 - #return 3
   - boolean :  For footer match
   - number  :  Level of header
   - string  :  Header stripped of left whitespace and tars


```lua
function cb.matchFoot(str)
    if str ~= "" and L.match(m.codefinish, str) then
        local trimmed = str:sub(L.match(m.WS * m.hax    , str))
        local level = L.match(m.fass, trimmed) - 1
        local bareline = trimmed:sub(L.match(m.fass, trimmed))
        return true, level, bareline
    else 
        return false, 0, ""
    end
end
```

 Constructor

```lua
local function new(Codeblock, level, headline, linum)
    local codeblock = setmetatable({}, CB)
    codeblock.level = level
    codeblock.header = headline
    codeblock.lang = L.match(L.C(m.symbol), headline) or ""
    codeblock.footer = ""
    codeblock.line_first = linum
    codeblock.lines = {}

    return codeblock
end


cb.__call = new
cb.__index = cb

return setmetatable({}, cb)
```
