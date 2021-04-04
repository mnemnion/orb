# Table


A subgrammar for parsing table blocks\.

```lua
local Peg  = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local fragments = require "orb:orb/fragments"
local Twig      = require "orb:orb/metas/twig"
```

```peg
      table  ←  WS* handle* WS* row+
        row  ←  WS* pipe cell (!table-end pipe cell)* table-end
       cell  ←  (!table-end !pipe 1)+
       pipe  ←  "|"
`table-end`  ←  (pipe / hline / double-row)* line-end
      hline  ←  "~"
 double-row  ←  "\\"
         WS  ←  " "+
   line-end  ←  (block-sep / "\n" / -1)
  block-sep  ←  "\n\n" "\n"*
```

```lua
table_str = table_str .. fragments.handle .. fragments.symbol
```

```lua
local table_grammar = Peg(table_str, {Twig})
```

```lua
return subGrammar(table_grammar, nil, "table-nomatch")
```
