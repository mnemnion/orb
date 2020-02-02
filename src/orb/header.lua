



local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"



local header_str = [[
        header  ←  " "* level head-line
         level  ←  "*"+
     head-line  ←  (" " header-text) / -1
   header-text  ←  1*
]]



local header_grammar = Peg(header_str)




return subGrammar(header_grammar.parse, nil, "header-nomatch")
