




local L = require "lpeg"

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
local s = require "singleton/status" ()
local epeg = require "espalier/elpatt"
local Csp = epeg.Csp
local Node = require "espalier/node"

local m = require "Orbit/morphemes"
local Link = require "Orbit/link"
local Richtext = require "Orbit/richtext"
local Grammar = require "espalier/grammar"


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
local inter_open, inter_close   =  bookends("`")



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





















local punct = m.punctuation

local function prose_gm(_ENV)
   START "prose"

   SUPPRESS ("anchorboxed", "urlboxed", "richtext",
             "literalwrap", "boldwrap", "italicwrap", "interpolwrap")

   prose = (V"link" + (V"prespace" * V"richtext") + V"raw")^1

   link = m.sel * m.WS * V"anchorboxed" * (m._ + m.NL)^0 * V"urlboxed" * m.ser
   anchorboxed = m.sel * m.WS * V"anchortext" * m.ser
   urlboxed = m.sel * m.WS * V"url" * m.WS * m.ser
   anchortext = m.anchor_text
   url = m.url

   richtext =  (V"literalwrap"
            +  V"boldwrap"
            +  V"italicwrap"
            +  V"interpolwrap") * #(m.WS + m.punctuation)
   literalwrap = lit_open * V"literal" * lit_close
   literal = (P(1) - lit_close)^1 -- These are not even close to correct
   boldwrap = bold_open * V"bold" * bold_close
   bold = (P(1) - bold_close)^1
   italicwrap = italic_open * V"italic" * italic_close
   italic = (P(1) - italic_close)^1
   interpolwrap = inter_open * V"interpolated" * inter_close
   interpolated = (P(1) - inter_close)^1 -- This may even be true

   -- This is the catch bucket.
   raw = (P(1) - (V"link" + (V"prespace" * V"richtext")))^1

   -- This is another one.
   prespace = m._ + m.NL
end

local function proseBuild(prose, str)
   return setmetatable(prose, {__index = Pr})
end

local proseMetas = { prose = proseBuild,
                     -- ßprespace = proseBuild,
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
