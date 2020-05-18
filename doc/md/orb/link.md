# Link


  A [link](httk://this.page) is borrowed more-or-less wholesale from org
mode.


A confession: I've dragged my heels on developing the inner syntax for links.


But they're pretty easy to define for now:

```lua
local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local Twig = require "orb:orb/metas/twig"
```
```lua
local link_str = [[
   link         =  link-head link-text link-close
                   (link-open link-anchor link-close)? link-close
   link-head    =  "[["
   link-close   =  "]"
   link-open    =  "["
   link-text    =  (!"]" 1)*
   link-anchor  =  (!"]" 1)*
]]
```
```lua
local link_M = Twig :inherit "link"
```
```lua
function link_M.toMarkdown(link, skein)
   local phrase = "["
   phrase = phrase .. link :select "link_text"() :span() .. "]"
   phrase = phrase .. "(" .. link :select "link_anchor"() :span() .. ")"
   return phrase
end
```
```lua
local link_grammar = Peg(link_str, { Twig, link = link_M })
```
```lua
return subGrammar(link_grammar.parse, "link-nomatch")
```