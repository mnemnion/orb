








local Peg = require "espalier:peg"
local prose_str = [[
   prose = italic / bold / raw
   bold =  bold-start (!bold-end non-bold) bold-end
   `bold-start` = ("*"+)$bold-c
   `bold-end` = ("*"+)$bold-c$
   italic = "placeholder"
   `non-bold` = italic / raw
   raw = (!bold-end !italic 1)*
]]
return Peg(prose_str)
