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
``Grammar.define`` doesn't as yet incorporate simply receiving a
metatable, it needs to take the fancy builder even if it isn't
going to use it. 

```lua
local Lit, lit = u.inherit(Node)
```
### toMarkdown

The all-important!


- [ ] #todo  This will overflow with more than one backtick.
       We need to count the longest internal sequence of
       '`' in the ``toValue()`` string.


       Since this is an operation we'll be doing a lot,
       it's an early candidate for an enhanced String
       library.

```lua
function Lit.toMarkdown(literal)
  return "``" .. literal:toValue() .. "``"
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
## Interpolated

  This will eventually be quite the complex class, and likely moved to
its own file.


Right now, we just need to strip the wrapper so that toMarkdown doesn't
turn it into a code block. 

```lua
local Interpol = u.inherit(Node)

function Interpol.toMarkdown(interpol)
  return interpol:toValue()
end 

```
### Constructor


```lua
return { literal = Lit, 
     italic  = Ita,
     bold    = Bold,
     interpolated = Interpol }
```
