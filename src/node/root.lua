







local Node = require "node/node"
local u = require "util"






local R, r = u.inherit(Node)



local function new(Root, str)
  local root = setmetatable({}, R)
  root.str = str
  return root
end



return u.export(r, new)
