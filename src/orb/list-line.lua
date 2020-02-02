




local subGrammar = require "espalier:espalier/subgrammar"
local Peg = require "espalier:espalier/peg"
local Twig = require "orb:orb/metas/twig"



local listline_str = [[
     list-line  ←  depth number* sep WS cookie* (key colon val / text)
         depth  ←  " "*
        number  ←  [0-9]+
           sep  ←  "-" / "."
       cookie   ←  "[" (!"]" 1)+ "]"
           key  ←  !":"
         colon  ←  ":"
           val  ←  1+
          text  ←  1+
            WS  ← " "+
]]



local listline_grammar = Peg(listline_str)



return subGrammar(listline_grammar.parse, nil, "listline-nomatch")
