




local L = require "lpeg"

local u = require "util"
local epnf = require "peg/epnf"
local Node = require "peg/node"

local m = require "grym/morphemes"

local Link = require "grym/link"


local Pr, pr = u.inherit(Node)






























local function equal_strings(s, i, a, b)
   -- Returns true if a and b are equal.
   -- s and i are not used, provided because expected by Cb.
   return a == b
end

local function bookends(sigil)
  local Cg, C, P, Cmt, Cb = L.Cg, L.C, L.P, L.Cmt, L.Cb
   -- Returns a pair of patterns, _open and _close,
   -- which will match a brace of sigil.
   -- sigil must be a string. 
   local _open = Cg(C(P(sigil)^1), sigil .. "_init")
   local _close =  Cmt(C(P(sigil)^1) * Cb(sigil .. "_init"), equal_strings)
   return _open, _close
end

local bold_open, bold_close     =  bookends("*")
local italic_open, italic_close =  bookends("/")
local under_open, under_close   =  bookends("_")
local strike_open, strike_close =  bookends("-")
local lit_open, lit_close       =  bookends("=")



function Pr.toMarkdown(prose)
  return prose.val
end



















function Pr.parse(prose)
  local P, C, Ct, Cg = L.P, L.C, L.Ct, L.Cg
  local raw_patt = (P(1) - m.link)^1
  local link_raw = L.match(Ct((Cg(m.link, "link") + Cg(raw_patt, "raw"))^1), prose.val)
  for _, v in ipairs(link_raw) do
    if v["link"] then
      io.write(v["link"])
    end
  end
  return prose
end






local function new(Prose, block)
    local prose = setmetatable({},Pr)
    prose.id = "prose"
    prose.val = "\n"
    for _,l in ipairs(block.lines) do
      prose.val = prose.val .. l .. "\n"
    end

    return prose:parse()
end



return u.export(pr, new)
