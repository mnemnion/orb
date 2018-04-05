


local L = require "lpeg"

local m = require "grym/morphemes"
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



function Li.parse(link, line)
  -- This only parses double links, expand
  local WS, sel, ser = m.WS, m.sel, m.ser
  local link_content = L.match(L.Ct(sel * WS * sel * L.C(m.anchor_text)
                * ser * WS * sel * L.C(m.url) * WS * ser * WS * ser),
                line)
  if link_content then
    link.prose = link_content[1] or ""
    link.url   = link_content[2] or ""
  end
  return link
end






return Li
