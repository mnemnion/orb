


















local Peg = require "espalier:peg"
local Node = require "espalier:node"



local Header = require "orb:orb/header"



local Doc_str = [[
            doc  ←  first-section* section+
`first-section`  ←  blocks

        section  ←  header line-end blocks*
         header  ←  "*"+ " " (!"\n" 1)* ; this is one which we subclass
                   / "*"+ &"\n"

       `blocks`  ←  block (block-sep block)* block-sep*
          block  ←  codeblock / table / list / (!"\n\n" !header 1)+
    `block-sep`  ←  "\n\n" "\n"*

     codeblock   ←  code-start (!code-end 1)* code-end
   `code-start`  ←  "#" ("!"+)@codelevel code-name@code_c (!"\n" 1)* "\n"
     `code-end`  ←  "\n" "#" ("/"+)@(#codelevel) code-name@(code_c)
                     (!"\n" 1)* line-end
    `code-name`  ←  (([a-z]/[A-Z]) ([a-z]/[A-Z]/[0-9]/"-"/"_")*)*

          table  ←  "placeholder"
           list  ←  "placeholder"

     `line-end`  ←  (block-sep / "\n" / -1)
]]





local DocMetas = { header = Header}



return Peg(Doc_str, DocMetas)
