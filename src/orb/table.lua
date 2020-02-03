





local fragments = require "orb:orb/fragments"
local Peg  = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"



local table_str = [[
      table  ←  WS* handle* WS* row+
        row  ←  WS* pipe cell (!table-end pipe cell)* table-end
       cell  ←  (!table-end !pipe 1)+
       pipe  ←  "|"
`table-end`  ←  (pipe / hline / double-row)* row-end
      hline  ←  "~"
 double-row  ←  "\\"
         WS  ←  " "+
    row-end  ←  "\n"+ / -1

]] .. fragments.handle .. fragments.symbol



local table_grammar = Peg(table_str)



return subGrammar(table_grammar, nil, "table-nomatch")
