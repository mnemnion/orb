# Header


```lua
local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"
```
```lua
local header_str = [[
     header  <-  " "* level head-line
      level  <-  "*"+
  head-line  <-  (" " header-text) / -1
  header-text <- 1*
]]
```
```lua
local header_grammar = Peg(header_str)
```
```lua
return subGrammar(header_grammar.parse, "header-nomatch")
```
