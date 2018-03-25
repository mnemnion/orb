




local L = require "lpeg"

local u = require "util"
local epnf = require "peg/epnf"
local Node = require "peg/node"

local m = require "grym/morphemes"

local Link = require "grym/link"


local Pr, pr = u.inherit(Node)































local Cg = L.Cg
local C = L.C
local P = L.P
local Cmt = L.Cmt
local Cb = L.Cb



local function equal_strings(s, i, a, b)
   -- Returns true if a and b are equal.
   -- s and i are not used, provided because expected by Cb.
   return a == b
end

local function bookends(sigil)
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




















local function new(Prose, block)
    local prose = setmetatable({},Pr)
    prose.id = "prose"
    prose.val = ""
    for _,l in ipairs(block.lines) do
      prose.val = prose.val .. l .. "\n"
    end
    return prose
end



return u.export(pr, new)
