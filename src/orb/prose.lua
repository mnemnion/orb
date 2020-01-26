






local Peg = require "espalier:peg"
local prose_str = [[
            prose ←  (italic / bold / raw)+
             bold ←   bold-start non-bold bold-end
     `bold-start` ←  "*"+@bold-c !(" " / "\n")
       `bold-end` ←  "*"+@(bold-c)
           italic ←  italic-start non-italic italic-end
     `non-italic` ←  (bold / (!italic-end 1))*
   `italic-start` ←  "/"+@italic-c
     `italic-end` ←  "/"+@(italic-c)
       `non-bold` ←  (!bold-end
                        (italic
                        / ((!italic fill)* WS+)* (!italic fill)
                        / ((!italic fill)* WS+)* italic
                        / (!italic fill)))+
        `fill`  =  !WS 1
        `WS` = (" " / "\n")
              raw ←  (!bold !italic 1)+
]]
return Peg(prose_str)
