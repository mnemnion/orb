























local L = require "lpeg"

local m = require "orb:Orbit/morphemes"
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
local s = require "status:status" ()

local Node = require "espalier/node"




local Li, li = u.inherit(Node)













function Li.toMarkdown(link)
  local anchor_text = ""
  local url = ""
  if link[1].id == "anchortext" then
    anchor_text = link[1]:toValue()
  end
  if link[2].id == "url" then
    url = link[2]:toValue()
  end

  return "[" .. anchor_text .. "]"
      .. "(" .. url .. ")"
end






return Li
