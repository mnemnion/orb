






local Peg = require "espalier:peg"
local prose_str = [[
            prose ←  (italic / bold / raw)+
             bold ←   bold-start non-bold bold-end
     `bold-start` ←  "*"+@bold-c
       `bold-end` ←  "*"+@(bold-c)
           italic ←  italic-start non-italic italic-end
     `non-italic` ←  (bold / (!italic-end 1))*
   `italic-start` ←  "/"+@italic-c
     `italic-end` ←  "/"+@(italic-c)
       `non-bold` ←  (italic / (!bold-end !italic fill)* (" " / "\n")+)*
                      (!bold-end !italic fill)+
        `fill`  =  (!" " !"\n" 1)
              raw ←  (!bold !italic 1)+
]]
return Peg(prose_str)
