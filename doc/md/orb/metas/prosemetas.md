#


```lua
local Twig = require "orb:orb/metas/twig"

local Phrase = require "singletons:singletons/phrase"
```

```lua
local function bookmaker(icon)
   return function(bookended, scroll)
      scroll:add(icon)
      for i = 2, #bookended - 1 do
         bookended[i]:toMarkdown(scroll)
      end
      scroll:add(icon)
   end
end
```

```lua
local bold_M = Twig:inherit "bold"
bold_M.toMarkdown = bookmaker "**"
```

```lua
local italic_M = Twig:inherit "italic"
italic_M.toMarkdown = bookmaker "*"
```

Literals we have to handle slightly differently, since any escapes in the
string would be a mistake here, and hence, we have to detect any backticks and
use more ````` if necessary\.

```lua
local literal_M = Twig:inherit "literal"

local find, rep = assert(string.find), assert(string.rep)

function literal_M.toMarkdown(literal, scroll)
   local span = literal :select "body"() :span()
   local ends = "`"
   local head, tail = find(span, "%`+")
   if head then
      ends = rep("`", tail + 2 - head)
   end
   scroll:add(ends .. span .. ends)
end
```

```lua
local strike_M = Twig:inherit "strike"
strike_M.toMarkdown = bookmaker ""
```

```lua
local underline_M = Twig:inherit "underline"
underline_M.toMarkdown = bookmaker ""
```

```lua
local verbatim_M = Twig:inherit "verbatim"
verbatim_M.toMarkdown = bookmaker ""
```

```lua
local Prose_M = { bold = bold_M,
                  italic = italic_M,
                  literal = literal_M,
                  strike = strike_M,
                  underline = underline_M,
                  verbatim = verbatim_M, }
```


```lua
return Prose_M
```
