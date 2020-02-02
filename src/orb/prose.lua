





local Peg = require "espalier:peg"
local Twig = require "orb:orb/metas/twig"



local prose_str = [[
               prose  ←  ( escape
                          / link
                          / italic
                          / bold
                          / strike
                          / literal
                          / verbatim
                          / underline
                          / raw )+

              escape  ←  "\\" {*/~_=}
                link  ←  "[[" (!"]"1)+ "]" ("[" (!"]" 1)+ "]")* "]"

                bold  ←   bold-start bold-body bold-end
        `bold-start`  ←  "*"+@bold-c !WS
          `bold-end`  ←  "*"+@(bold-c)
         `bold-body`  ←  ( WS+ (!non-bold !bold-end fill)+
                          / WS* non-bold
                          / (!non-bold !bold-end fill)+ )+
         `non-bold`   ←  italic / strike / underline /literal

              italic  ←  italic-start italic-body italic-end
      `italic-start`  ←  "/"+@italic-c !WS
        `italic-end`  ←  "/"+@(italic-c)
       `italic-body`  ←  ( WS+ (!non-italic !italic-end fill)+
                          / WS* non-italic
                          / (!non-italic !italic-end fill)+ )+
       `non-italic`   ←  bold / strike / underline / literal

              strike  ←  strike-start strike-body strike-end
      `strike-start`  ←  "~"+@strike-c !WS
        `strike-end`  ←  "~"+@(strike-c)
       `strike-body`  ←  ( WS+ (!non-strike !strike-end fill)+
                                / WS* non-strike
                                / (!non-strike !strike-end fill)+ )+
        `non-strike`  ←  bold / italic / underline / literal

           underline  ←  underline-start underline-body underline-end
   `underline-start`  ←  "_"+@underline-c !WS
     `underline-end`  ←  "_"+@(underline-c)
    `underline-body`  ←  ( WS+ (!non-underline !underline-end fill)+
                             / WS* non-underline
                             / (!non-underline !underline-end fill)+ )+
     `non-underline`  ←  bold / italic / strike /literal

            literal  ←  literal-start literal-body literal-end
    `literal-start`  ←  "="+@literal-c
      `literal-end`  ←  "="+@(literal-c)
     `literal-body`  ←  (!literal-end 1)+

     verbatim  ←  verbatim-start verbatim-body verbatim-end
    `verbatim-start`  ←  ("`" "`"+)@verbatim-c
      `verbatim-end`  ←  ("`" "`"+)@(verbatim-c)
     `verbatim-body`  ←  (!verbatim-end 1)+

              `fill`  ←  !WS 1
                `WS`  ←  (" " / "\n")
                raw   ←  ( !bold
                            !italic
                            !strike
                            !literal
                            !verbatim
                            !underline
                            !escape
                            !link 1 )+
]]








local Raw = Twig : inherit "raw"

function Raw.strLine(raw)
   return ""
end







local proseMetas = {
                     raw = Raw,
                               }

local prose_grammar = Peg(prose_str, proseMetas)









local function prose_fn(t)
   local match = prose_grammar(t.str, t.first, t.last)
   if match then
       if match.last == t. last then
         -- label the match according to the rule
         match.id = t.id or "prose"
         return match
       else
         match.id = t.id .. "-INCOMPLETE"
         return match
       end
   end
   -- if error:
   t.id = "prose-nomatch"
   return setmetatable(t, Node)
end



return prose_fn
