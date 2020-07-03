













local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local Twig = require "orb:orb/metas/twig"



local link_str = [[
   link         ←  link-head link-text link-close WS*
                   (link-open link-anchor link-close)? link-close

                /  link-head link-text link-close obelus link-close
   link-head    ←  "[["
   link-close   ←  "]"
   link-open    ←  "["
   link-text    ←  (!"]" 1)*
   link-anchor  ←  (!"]" 1)*
   obelus       ←  (!"]" 1)+
            WS  ←  { \n}+
]]



local link_M = Twig :inherit "link"



function link_M.toMarkdown(link, skein)
   local link_text = link:select("link_text")()
   link_text = link_text and link_text:span() or ""
   local phrase = "["
   phrase = phrase ..  link_text .. "]"
   local link_anchor = link:select("link_anchor")()
   link_anchor = link_anchor and link_anchor:span() or ""
   phrase = phrase .. "(" ..  link_anchor .. ")"
   return phrase
end



local link_grammar = Peg(link_str, { Twig, link = link_M })



return subGrammar(link_grammar.parse, "link-nomatch")
