
























local Peg = require "espalier:espalier/peg"
local metafn = require "espalier:espalier/metafn"

local fragments = require "orb:orb/fragments"



local code_str = [[
    codeblock  ←  code-start code-body code-end
   code-start  ←  "#" "!"+ code-type* (!"\n" 1)* "\n"
    code-body  ←  (!code-end 1)+
     code-end  ←  "#" "/"+ code-type*  (!"\n" 1)* line-end
    code-type  ←  symbol
   `line-end`  ←  ("\n\n" "\n"* / "\n")* (-1)
]] .. fragments.symbol



local code_peg = Peg(code_str)





return metafn(code_peg.parse, "code-nomatch")
