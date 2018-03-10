local u = require "lib/util"

local Node = require "peg/node"

local m = require "grym/morphemes"


local W, w = u.inherit(Node)

local function W.weave(weaver, doc)

end

local function new(Weaver, doc)
    local weaver = setmetatable({}, W)

    return weaver
end

