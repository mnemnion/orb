# Header Metas

Metatables for the header grammar\.

```lua
local Phrase = require "singletons:singletons/phrase"
local Twig = require "orb:orb/metas/twig"
```

```lua
local Header_M = {}
```

```lua
local Header = Twig:inherit "header"
Header_M.header = Header
```



```lua
function Header.toMarkdown(header, skein)
   local phrase = Phrase (("#"):rep(header:select("level")():len()))
   local head_line = header :select "head_line"()
   if head_line then
      return phrase .. head_line :toMarkdown(skein)
   else
      return phrase
   end
end
```

```lua
return Header_M
```