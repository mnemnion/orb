
























local Peg = require "espalier:espalier/peg"
local metafn = require "espalier:espalier/metafn"



local code_str = [[
    codeblock  ←  code-start code-body code-end
   code-start  ←  "#" "!"+ code-type* (!"\n" 1)* "\n"
    code-body  ←  (!code-end 1)+
     code-end  ←  "#" "/"+ code-type*  (!"\n" 1)* line-end
    code-type  ←  (([a-z]/[A-Z]) ([a-z]/[A-Z]/[0-9]/"-"/"_")*)
   `line-end`  ←  ("\n\n" "\n"* / "\n")* (-1)
]]



local code_peg = Peg(code_str)





return metafn(code_peg.parse, "code-nomatch")
