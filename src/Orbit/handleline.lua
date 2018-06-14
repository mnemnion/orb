




local Node = require "espalier/node"
local u = require "../lib/util"

local Handle = require "Orbit/handle"

local H, h = u.inherit(Node)

function H.toMarkdown(handleline)
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
