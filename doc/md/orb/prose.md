# Prose


Prose is the default parsing state for Orb documents.

```lua
local Peg = require "espalier:peg"

local Twig = require "orb:orb/metas/twig"
local fragments = require "orb:orb/fragments"

local ProseMetas = require "orb:orb/metas/prosemetas"
```
```lua
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

              escape  ←  "\\" {*/~_=`][}
                link  ←  "[[" (!"]"1)+ "]" ("[" (!"]" 1)+ "]")* "]"

                bold  ←   bold-start bold-body bold-end
        `bold-start`  ←  "*"+@bold-c !WS
          `bold-end`  ←  "*"+@(bold-c)
         `bold-body`  ←  ( WS+ (!non-bold !bold-end fill)+
                          / WS* non-bold
                          / (!non-bold !bold-end fill)+ )+
         `non-bold`   ←  italic / strike / underline / literal / verbatim

              italic  ←  italic-start italic-body italic-end
      `italic-start`  ←  "/"+@italic-c !WS
        `italic-end`  ←  "/"+@(italic-c)
       `italic-body`  ←  ( WS+ (!non-italic !italic-end fill)+
                          / WS* non-italic
                          / (!non-italic !italic-end fill)+ )+
       `non-italic`   ←  bold / strike / underline / literal / verbatim

              strike  ←  strike-start strike-body strike-end
      `strike-start`  ←  "~"+@strike-c !WS
        `strike-end`  ←  "~"+@(strike-c)
       `strike-body`  ←  ( WS+ (!non-strike !strike-end fill)+
                                / WS* non-strike
                                / (!non-strike !strike-end fill)+ )+
        `non-strike`  ←  bold / italic / underline / literal / verbatim

           underline  ←  underline-start underline-body underline-end
   `underline-start`  ←  "_"+@underline-c !WS
     `underline-end`  ←  "_"+@(underline-c)
    `underline-body`  ←  ( WS+ (!non-underline !underline-end fill)+
                             / WS* non-underline
                             / (!non-underline !underline-end fill)+ )+
     `non-underline`  ←  bold / italic / strike / literal / verbatim

            literal  ←  literal-start literal-body literal-end
    `literal-start`  ←  "="+@literal-c
      `literal-end`  ←  "="+@(literal-c)
     `literal-body`  ←  (!literal-end 1)+

     verbatim  ←  verbatim-start verbatim-body verbatim-end
    `verbatim-start`  ←  ("`" "`"+)@verbatim-c
      `verbatim-end`  ←  ("`" "`"+)@(verbatim-c)
     `verbatim-body`  ←  (!verbatim-end 1)+

              `fill`  ←  !WS 1
                WS    ←  (" " / "\n")
              `raw`   ←  ( !bold
                            !italic
                            !strike
                            !literal
                            !verbatim
                            !underline
                            !escape
                            !link (word / punct / WS) )+
              word  ←  (!t 1)+
             punct  ←  {\n.,:;?!)(][\"}+
]] .. fragments.t .. fragments.utf8
```
```lua
local proseMetas = { Twig,
                      WS   =  require "orb:orb/metas/ws",
                      link =  require "orb:orb/link"  }

local prose_grammar = Peg(prose_str, proseMetas)
```
### prose_fn(t)

We want to do something slightly different with prose, so this is based on
``espalier/subgrammar``, with some modifications.

```lua
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
```
```lua
return prose_fn
```
