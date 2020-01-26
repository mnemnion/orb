






local Peg = require "espalier:peg"
local prose_str = [[
            prose ←  (italic / bold / raw)+

             bold ←   bold-start non-bold bold-end
     `bold-start` ←  "*"+@bold-c !(" " / "\n")
       `bold-end` ←  "*"+@(bold-c)
       `non-bold` ←  (!bold-end
                        ( italic
                        / WS+ (!italic fill)+
                        / WS+ italic
                        / (!italic fill)+ ))+

           italic ←  italic-start non-italic italic-end
   `italic-start` ←  "/"+@italic-c
     `italic-end` ←  "/"+@(italic-c)
     `non-italic` ←  (bold / (!italic-end 1))*

           `fill` ←  !WS 1
             `WS` ←  (" " / "\n")
             raw  ←  (!bold !italic 1)+
]]
return Peg(prose_str)
