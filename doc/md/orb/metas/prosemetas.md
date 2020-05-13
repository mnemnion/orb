# Prose Metatables


```lua
local Twig = require "orb:orb/metas/twig"

local Phrase = require "singletons:singletons/phrase"
```
```lua
local Prose_M = {}
```
```lua
local link = Twig :inherit "link"
Prose_M.link = link
```
```lua
function link.toMarkdown(link, skein)
   local phrase = "["
   phrase = phrase .. link:select ""
   -- at this instant I realize I haven't written an inner parser for
   -- links, and that's largely because I haven't wanted to commit to
   -- a syntax. >.<
   return phrase
end
```
```lua
return Prose_M
```
