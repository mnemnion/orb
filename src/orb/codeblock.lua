
























local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local fragments = require "orb:orb/fragments"
local Twig = require "orb:orb/metas/twig"



local code_str = [[
    codeblock  ←  code-start code-body  code-end
   code-start  ←  "#" "!"+ code-type* (" "+ name)* rest* "\n"
    code-body  ←  (!code-end 1)+
     code-end  ←  "#" "/"+ code-type* execute* (!"\n" 1)* line-end
               /  -1
    code-type  ←  symbol
   `line-end`  ←  ("\n\n" "\n"* / "\n")* (-1)
         name  ←  handle
      execute  ←  "(" " "* ")"
       `rest`  ←  (handle / hashtag / raw)+
         raw   ←  (!handle !hashtag !"\n" 1)+
]] .. fragments.symbol .. fragments.handle .. fragments.hashtag



local code_peg = Peg(code_str, {Twig})





return subGrammar(code_peg.parse, nil, "code-nomatch")
