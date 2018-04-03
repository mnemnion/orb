


local L = require "lpeg"

local m = require "grym/morphemes"
local u = require "util"
local s = require "status" ()

local Node = require "node/node"




local Li, li = u.inherit(Node)
Li.id = "link"







function Li.toMarkdown(link)
  url = link.url or ""
  prose = link.prose or ""
  return "[" .. prose .. "]"
      .. "(" .. url .. ")"
end





function Li.dotLabel(link)
  return "link: " .. (link.prose or "")
end



function Li.parse(link, line)
  -- This only parses double links, expand
  local WS, sel, ser = m.WS, m.sel, m.ser
  local link_content = L.match(L.Ct(sel * WS * sel * L.C(m.link_prose)
                * ser * WS * sel * L.C(m.url) * WS * ser * WS * ser),
                line)
  if link_content then
    link.prose = link_content[1] or ""
    link.url   = link_content[2] or ""
  end
  return link
end





local function new(Link, line)
  local link = setmetatable({},Li)
  link.id = "link"
  link.val = line -- refine this
  link:parse(line)
  return link
end




local function linkbuild(link, str)
  s:verb("   ~~ built a link")
  setmetatable(link, Li)
  return Li.parse(link, str:sub(link.first, link.last))
end





return linkbuild
