# Doc Metatables


Metatables for the \(outermost\) Doc parser\.

```lua
local Twig = require "orb:orb/metas/twig"
local Phrase = require "singletons:singletons/phrase"
```

```lua
local DocMetas = {}
```

## Doc metatable \(singular\)

The root metatable for a Doc\.

```lua
local Doc_M = Twig:inherit "doc"
DocMetas.doc = Doc_M
```

```lua
function Doc_M.toMarkdown(doc, scroll)
   local phrase = Phrase ""
   for _, block in ipairs(doc) do
      phrase = phrase .. block:toMarkdown(scroll)
   end
   return phrase
end
```

```lua
local Section_M = Twig:inherit "section"
DocMetas.section = Section_M
```

```lua
function Section_M.toMarkdown(section, scroll)
   local phrase = Phrase ""
   for _, block in ipairs(section) do
      phrase = phrase .. block:toMarkdown(scroll)
   end
   return phrase
end
```

```lua
return DocMetas
```
