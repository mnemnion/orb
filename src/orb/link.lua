










local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local Twig = require "orb:orb/metas/twig"



local link_str = [[
   link         =  link-head link-text link-close
                   (link-open link-anchor link-close)? link-close
   link-head    =  "[["
   link-close   =  "]"
   link-open    =  "["
   link-text    =  (!"]" 1)*
   link-anchor  =  (!"]" 1)*
]]



local link_M = Twig :inherit "link"



function link_M.toMarkdown(link, skein)
   local phrase = "["
   phrase = phrase .. link :select "link_text"() :span() .. "]"
   phrase = phrase .. "(" .. link :select "link_anchor"() :span() .. ")"
   return phrase
end



local link_grammar = Peg(link_str, { Twig, link = link_M })



return subGrammar(link_grammar.parse, "link-nomatch")
