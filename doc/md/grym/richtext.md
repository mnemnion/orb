# Rich Text Metas


  This is a collection of related methods for handling rich text markup
inside of prose blocks. 


### includes

```lua
local Node = require "node"

local u = require "util"

local L = require "lpeg"
```
## Literal

  I am preparing the Literal table in the usual fashion, because 
`````Grammar.define````` doesn't as yet incorporate simply receiving a
metatable, it needs to take the fancy builder even if it isn't
going to use it. 

```lua
local Lit, lit = u.inherit(Node)
```
### toMarkdown

The all-important!


- [ ] #todo  Actually count internal backticks instead of just
             whanging on the count past any plausible inclusion.

```lua
function Lit.toMarkdown(literal)
  return "`````" .. literal:toValue() .. "`````"
end
```
## Italic

```lua
local Ita = u.inherit(Node)

function Ita.toMarkdown(italic)
  return "_" .. italic:toValue():gsub("_", "\\_") .. "_"
end
```
## Bold

```lua
local Bold = u.inherit(Node)

function Bold.toMarkdown(bold)
  return "**" .. bold:toValue():gsub("*", "\\*") .. "**"
end
```
### Constructor


```lua
return { literal = Lit, 
     italic  = Ita,
     bold    = Bold }
```
