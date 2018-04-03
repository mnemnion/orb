# Handleline module
   A minimalist Node container for a handle line.

```lua
local Node = require "peg/node"
local u = require "../lib/util"

local Handle = require "grym/handle"

local H, h = u.inherit(Node)

local function toMarkdown(handleline)
  return handleline.__VALUE
end

local function new(Handleline, line)
    local handleline = setmetatable({}, H)
    handleline.__VALUE = line
    handleline.id = "handleline"
    handleline[1] = Handle(line)

    return handleline
end


return u.export(h, new)
```
