



local L = require "lpeg"

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

local m = require "orb:Orbit/morphemes"

local H, h = u.inherit(Node)

function h.matchHandle(line)
    local handlen = L.match(L.C(m.handle), line)
    if handlen then
        return handlen

    else
        return ""
        --u.freeze("h.matchHandle fails to match a handle")
    end
end

local function new(Handle, line)
    local handle = setmetatable({}, H)
    handle.id = "handle"
    handle.val = h.matchHandle(line):sub(2, -1)
    return handle
end

return u.export(h, new)
