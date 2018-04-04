




local Node = require "node/node"
local u = require "../lib/util"

local Hashtag = require "grym/hashtag"

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
