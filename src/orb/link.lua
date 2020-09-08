













local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local Twig = require "orb:orb/metas/twig"



local link_str = [[
   link         ←  link-head link-text link-close WS*
                   (link-open anchor link-close)? link-close
                /  link-head link-text link-close obelus link-close

   link-head    ←  "[["
   link-close   ←  "]"
   link-open    ←  "["
   link-text    ←  (!"]" 1)*
   anchor       ←  handle-ref / url / bad-form
   handle-ref   ←  "@" (!"]" 1)*
   url          ←  "http://example.com"
   bad-form     ←  (!"]" 1)*
   obelus       ←  (!"]" 1)+
   WS           ←  { \n}+
]]



local link_M = Twig :inherit "link"



local function obelusPred(ob_mark)
   return function(twig)
      local obelus = twig:select "obelus" ()
      if obelus and obelus:span() == ob_mark then
         return true
      end
      return false
   end
end

function link_M.toMarkdown(link, skein)
   local link_text = link:select("link_text")()
   link_text = link_text and link_text:span() or ""
   local phrase = "["
   phrase = phrase ..  link_text .. "]"
   local link_anchor = link:select("anchor")()
   if link_anchor then
      link_anchor = link_anchor:span()
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
            link_anchor = "link line not found"
         end
      else
         link_anchor = ""
      end
   end
   phrase = phrase .. "(" ..  link_anchor .. ")"
   return phrase
end



local link_grammar = Peg(link_str, { Twig, link = link_M })



return subGrammar(link_grammar.parse, "link-nomatch")
