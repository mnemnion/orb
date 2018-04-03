


local L = require "lpeg"

local m = require "grym/morphemes"
local u = require "util"

local Node = require "peg/node"




local Li, li = u.inherit(Node)
Li.id = "link"







function Li.toMarkdown(link)
  return "[" .. link.prose .. "]"
      .. "(" .. link.url .. ")"
end





function Li.dotLabel(link)
  return "link: " .. link.prose
end



function Li.parse(link, line)
  -- This only parses double links, expand
  local WS, sel, ser = m.WS, m.sel, m.ser
  local link_content = L.match(L.Ct(sel * WS * sel * L.C(m.link_prose)
                * ser * WS * sel * L.C(m.url) * WS * ser * WS * ser),
                line)
  link.prose = link_content[1] or ""
  link.url   = link_content[2] or ""
  return link
end





local function new(Link, line)
  local link = setmetatable({},Li)
  link.id = "link"
  link.val = line -- refine this
  link:parse(line)
  return link
end




local function linkbuild(link, line)
  io.write("   ~~ built a link\n")
  link = setmetatable({}, Li)
  return Li.parse(link, line)
end





return linkbuild
