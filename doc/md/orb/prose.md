# Prose

For now, I'm going to use this as a scratch pad to test nested matched
captures.


The Lpeg documentation makes it clear enough when capture groups are
discarded, but I'm still in the dark about my specific use case.

```lua
local Peg = require "espalier:peg"
local prose_str = [[
   prose = (italic / bold / raw)+
   bold =  bold-start non-bold bold-end
   `bold-start` = ("*"+)$bold-c
   `bold-end` = ("*"+)$bold-c$
   italic = italic-start non-italic italic-end
   `non-italic` = (bold / (!italic-end 1))*
   `italic-start` = ("/"+)$italic-c
   `italic-end`   = ("/"+)$italic-c$
   `non-bold` = (italic / (!bold-end 1))*
   raw = (!bold !italic 1)+
]]
return Peg(prose_str)
```
