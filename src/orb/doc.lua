


















local Peg = require "espalier:peg"
local Node = require "espalier:node"



local Header = require "orb:orb/header"
local Codeblock = require "orb:orb/codeblock"
local fragments = require "orb:orb/fragments"



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
   `code-start`  ←  "#" ("!"+)@codelevel code-type@code_c (!"\n" 1)* "\n"
     `code-end`  ←  "\n" "#" ("/"+)@(#codelevel) code-type@(code_c)
                     (!"\n" 1)* line-end
    `code-type`  ←  symbol

          table  ←  "placeholder"
           list  ←  "placeholder"

     `line-end`  ←  (block-sep / "\n" / -1)
]] .. fragments.symbol





local DocMetas = { header = Header,
                   codeblock = Codeblock, }



return Peg(Doc_str, DocMetas)
