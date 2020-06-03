# Header


```lua
local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local Twig = require "orb:orb/metas/twig"
local Header_M = require "orb:orb/metas/headermetas"
```

```lua
local header_str = [[
        header  ←  WS? level (head-line / -1)
         WS     ←  " "+
         level  ←  "*"+
     head-line  ←  (" " 1*)
]]
```

```lua
local addall = assert(require "core:core/table" . addall)
local head_M = {Twig}
addall(head_M, Header_M)
local header_grammar = Peg(header_str, head_M)
```


```lua
return subGrammar(header_grammar.parse, "header-nomatch")
```