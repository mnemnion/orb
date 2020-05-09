# Header


```lua
local Twig = require "orb:orb/metas/twig"
local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"
```
```lua
local header_str = [[
        header  ←  " "* level (head-line / -1)
         level  ←  "*"+
     head-line  ←  (" " header-text)
   header-text  ←  1*
]]
```
```lua
local header_grammar = Peg(header_str, {Twig})
```
```lua
return subGrammar(header_grammar.parse, "header-nomatch")
```
