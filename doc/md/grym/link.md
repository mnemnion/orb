# Link module

```lua
local L = require "lpeg"

local m = require "grym/morphemes"
local u = require "util"

local Node = require "peg/node"
```
```lua
local Li, li = u.inherit(Node)
```
## Transformers

### toMarkdown

```lua
function Li.toMarkdown(link)
  return "[" .. link.prose .. "]"
      .. "(" .. link.url .. ")"
end
```
### dotLabel

```lua
function Li.dotLabel(link)
  return "link: " .. link.prose
end
```
```lua
function Li.parse(link, line)
  -- This only parses double links, expand
  local WS, sel, ser = m.WS, m.sel, m.ser
  local link_content = L.match(L.Ct(sel * WS * sel * L.C(m.link_prose)
                * ser * WS * sel * L.C(m.url) * WS * ser * WS * ser),
                line)
  link.prose = link_content[1] or ""
  link.url   = link_content[2] or ""
  return link
end
```
```lua
local function new(Link, line)
  local link = setmetatable({},Li)
  link.id = "link"
  link.val = line -- refine this
  link:parse(line)
  return link
end
```
### export

```lua
return u.export(li, new)
```
