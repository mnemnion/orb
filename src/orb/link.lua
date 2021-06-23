











local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"
local fragments = require "orb:orb/fragments"
local WS  = require "orb:orb/metas/ws"
local Twig = require "orb:orb/metas/twig"

local Anchor = require "orb:orb/metas/anchor"

local s = require "status:status" ()
s.grumpy = true


local link_str = [[
   link         ←  link-head link-text link-close WS*
                   (link-open anchor link-close)
                   (WS* hashtag WS*)* link-close
                /  link-head anchor link-close
                   (WS* hashtag WS*)* link-close
                /  link-head link-text link-close obelus link-close

   link-head    ←  "[["
   link-close   ←  "]"
   link-open    ←  "["
   link-text    ←  (!"]" 1)*

   anchor       ←  (!"]" 1)+
   obelus       ←  (!"]" 1)+
   WS           ←  { \n}+
]]


link_str = link_str .. fragments.hashtag

local link_M = Twig :inherit "link"



local function obelusPred(ob_mark)
   return function(twig)
      if twig.id ~= 'link_line' then return false end

      local obelus = twig:select "obelus" ()
      if obelus and obelus:span() == ob_mark then
         return true
      end
      return false
   end
end

function link_M.toMarkdown(link, scroll, skein)
   local link_text = link:select("link_text")()
   link_text = link_text and link_text:span()
   local link_anchor = link:select("anchor")()
   if link_anchor then

      local ref = link_anchor:select "ref" ()
      if ref then
         link_anchor = ref:resolveLink(skein, "md")
      else
         link_anchor = link_anchor:span()
      end
   else
      -- look for an obelus
      local obelus = link:select("obelus")()
      if obelus then
         -- find the link_line
         local ob_pred = obelusPred(obelus:span())
         local link_line = link
                             :root()
                             :selectFrom(ob_pred, link.last + 1) ()
         if link_line then
            link_anchor = link_line :select "link" () :span()
         else
            local line_pos = obelus:linePos()
            local link_err = "link line not found for obelus: "
                             .. obelus:span() .. " on line " .. line_pos
            s:warn(link_err)
            scroll:addError(link_err)
            link_anchor = link_err
         end
      else
         link_anchor = ""
      end
   end
   if not link_text then
      link_text = link_anchor
   end
   local phrase = "[" .. link_text .. "]" .. "(" ..  link_anchor .. ")"
   scroll:add(phrase)
end



local Link_Metas = { Twig,
                     link = link_M,
                     anchor = Anchor,
                     WS   = WS, }
local link_grammar = Peg(link_str, Link_Metas)



return subGrammar(link_grammar.parse, "link-nomatch")

