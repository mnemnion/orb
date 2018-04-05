




local L = require "lpeg"

local u = require "util"
local s = require ("status")()
local epeg = require "epeg"
local Csp = epeg.Csp
local Node = require "node/node"

local m = require "grym/morphemes"
local Link = require "grym/link"
local Richtext = require "grym/richtext"
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
   for _, node in ipairs(prose) do
      if node.toMarkdown then
        phrase = phrase .. node:toMarkdown()
      elseif node.id == "raw" then
         phrase = phrase  .. node:toValue()
      end
   end
   return phrase
end









local function prose_gm(_ENV)
   START "prose"

   SUPPRESS ("anchorboxed", "urlboxed", "richtext",
             "literalwrap", "boldwrap", "italicwrap")

   prose = (V"link" + V"richtext" + V"raw")^1

   link = m.sel * m.WS * V"anchorboxed" * m.WS * V"urlboxed" * m.ser
   anchorboxed = m.sel * m.WS * V"anchortext" * m.ser
   urlboxed = m.sel * m.WS * V"url" * m.WS * m.ser
   anchortext = m.anchor_text
   url = m.url

   richtext = V"literalwrap" + V"boldwrap" + V"italicwrap" -- + V"underlined"
   literalwrap = lit_open * V"literal" * lit_close
   literal = (P(1) - lit_close)^1 -- This is not even close
   boldwrap = bold_open * V"bold" * bold_close
   bold = (P(1) - bold_close)^1
   italicwrap = italic_open * V"italic" * italic_close
   italic = (P(1) - italic_close)^1

   -- This is the catch bucket.
   raw = (P(1) - (V"link" + V"richtext"))^1
end

local function proseBuild(prose, str)
   return setmetatable(prose, {__index = Pr})
end

local proseMetas = { prose = proseBuild,
                     link  = Link }

for k, v in pairs(Richtext) do
  proseMetas[k] = v
end

local parse = Grammar(prose_gm, proseMetas)  










local function new(Prose, block)
    local phrase = "\n"
    for _,l in ipairs(block.lines) do
      phrase = phrase .. l .. "\n"
    end
    local prose = parse(phrase, 0) 
    return prose
end



return u.export(pr, new)
