# Hashline module

   A minimalist Node container for a hashline.

```lua
local Node = require "espalier/node"
local u = {}
function u.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end
function u.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
end

local Hashtag = require "orb:Orbit/hashtag"

local H, h = u.inherit(Node)

function H.toMarkdown(hashline)
  return hashline.__VALUE
end

local function new(Hashline, line)
    local hashline = setmetatable({}, H)
    hashline.id = "hashline"
    hashline.__VALUE = line
    hashline[1] = Hashtag(line)

    return hashline
end


return u.export(h, new)
```
