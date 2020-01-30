





local Peg = require "espalier:peg"
local subGrammar = require "espalier:subgrammar"



local prose_str = [[
               prose  ←  ( escape
                          / italic
                          / bold
                          / strike
                          / literal
                          / underline
                          / raw )+

              escape  ←  "\\" {*/~_=}

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

              `fill`  ←  !WS 1
                `WS`  ←  (" " / "\n")
                raw   ←  ( !bold
                            !italic
                            !strike
                            !literal
                            !underline
                            !escape 1 )+
]]



local prose_grammar = Peg(prose_str)









local function prose_fn(t)
   local match = prose_grammar(t.str, t.first, t.last)
      if match then
         if match.last == t. last then
            -- label the match according to the rule
            match.id = t.id
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