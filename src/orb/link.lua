










local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local Twig = require "orb:orb/metas/twig"



local link_str = [[
   link = "[[" link-text "]" ("[" link-anchor "]")? "]"
   link-text = (!"]" 1)*
   link-anchor = (!"]" 1)*
]]



local link_grammar = Peg(link_str, {Twig})



return subGrammar(link_grammar.parse, "link-nomatch")
