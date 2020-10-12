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
function Header.toMarkdown(header, scroll)
   local phrase = ("#"):rep(header:select("level")():len())
   scroll:add(phrase)
   local head_line = header :select "head_line"()
   if head_line then
      head_line :toMarkdown(scroll)
   end
end
```

```lua
return Header_M
```
