






local Peg = require "espalier:peg"
local prose_str = [[
            prose ←  (italic / bold / raw)+

             bold ←   bold-start non-bold bold-end
     `bold-start` ←  "*"+@bold-c !(" " / "\n")
       `bold-end` ←  "*"+@(bold-c)
       `non-bold` ←  ( WS+ (!italic !bold-end fill)+
                      / WS* italic
                      / (!italic !bold-end fill)+ )+

           italic ←  italic-start non-italic italic-end
   `italic-start` ←  "/"+@italic-c
     `italic-end` ←  "/"+@(italic-c)
     `non-italic` ←  ( WS+ (!bold !italic-end fill)+
                      / WS* bold
                      / (!bold !italic-end fill)+ )+

           `fill` ←  !WS 1
             `WS` ←  (" " / "\n")
             raw  ←  (!bold !italic 1)+
]]
return Peg(prose_str)
