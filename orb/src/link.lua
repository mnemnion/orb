























local L = require "lpeg"

local m = require "orb/morphemes"
local u = require "util"
local s = require "status" ()

local Node = require "node/node"




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
