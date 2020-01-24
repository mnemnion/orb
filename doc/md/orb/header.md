# Header


```lua
local Peg = require "espalier:espalier/peg"
local metafn = require "espalier:espalier/metafn"
```
```lua
local header_str = [[
     header  <-  level head-line
      level  <-  "*"+
  head-line  <-  (" " header-text) / -1
  header-text <- 1*
]]
```
```lua
local header_grammar = Peg(header_str)
```
```lua
return metafn(header_grammar.parse, "header-nomatch")
```
