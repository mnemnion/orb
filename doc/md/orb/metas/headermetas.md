# Header Metas

Metatables for the header grammar\.

```lua
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
function Header.toMarkdown(header, scroll, skein)
   local phrase = ("#"):rep(header:select("level")():len())
   scroll:add(phrase)
   for i = 2, #header do
      header[i]:toMarkdown(scroll, skein)
   end
end
```

```lua
return Header_M
```
