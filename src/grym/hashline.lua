




local Node = require "peg/node"
local u = require "../lib/util"

local Hashtag = require "grym/hashtag"

local H, h = u.inherit(Node)

local function new(Hashline, line)
    local hashline = setmetatable({}, H)
    hashline.id = "hashline"
    hashline[1] = Hashtag(line)

    return hashline 
end


return u.export(h, new)
