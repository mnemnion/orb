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
function Doc_M.toMarkdown(doc, scroll, skein)
   for _, block in ipairs(doc) do
      block:toMarkdown(scroll, skein)
   end
end
```


#### Doc:toSkein\(\)

This is a convenience function for working with Docs inside `helm`\.

```lua
local Skein;
function Doc_M.toSkein(doc)
   Skein = Skein or require "orb:orb/skein"
end
```

```lua
local Section_M = Twig:inherit "section"
DocMetas.section = Section_M
```

```lua
function Section_M.toMarkdown(section, scroll, skein)
   for _, block in ipairs(section) do
      block:toMarkdown(scroll, skein)
   end
end
```

```lua
return DocMetas
```
