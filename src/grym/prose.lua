




local L = require "lpeg"

local u = require "util"
local s = require ("status")()
local epnf = require "peg/epnf"
local epeg = require "peg/epeg"
local Csp = epeg.Csp
local Node = require "node/node"

local m = require "grym/morphemes"

local Link = require "grym/link"
local Grammar = require "node/grammar"


local Pr, pr = u.inherit(Node)
Pr.id = "prose"



s.chatty = false  





























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
   local phrase = ""
   for node in prose:walk() do
      if node.id == "link" then
         phrase = phrase .. "~~" .. node:toValue()
      elseif node.id == "raw" then
         phrase = phrase  .. node:toValue()
      end
   end
   return phrase
end











local function prose_gm(_ENV)
   START "prose"
   prose = (V"link" + V"raw")^1
   link = m.link
   raw = (P(1) - m.link)^1
end

local function proseBuild(prose, str)
   return setmetatable(prose, Pr)
end

local parse = Grammar(prose_gm, { prose = proseBuild})  










local function new(Prose, block)
    local phrase = "\n"
    for _,l in ipairs(block.lines) do
      phrase = phrase .. l .. "\n"
    end
    local prose = parse(phrase, 0) 
    return prose
end



return u.export(pr, new)
