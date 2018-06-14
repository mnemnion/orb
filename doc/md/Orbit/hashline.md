# Hashline module

   A minimalist Node container for a hashline.

```lua
local Node = require "espalier/node"
local u = require "../lib/util"

local Hashtag = require "Orbit/hashtag"

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
