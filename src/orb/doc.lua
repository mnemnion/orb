


















local Peg = require "espalier:peg"
local Node = require "espalier:node"




local Doc_str = [[
            doc <- first-section* section+
`first-section` <- blocks
        section <- header (block-sep / "\n" / -1) blocks*
         header <- "*"+  header-line
    header-line <- " " (!"\n" 1)* ; this is one which we subclass
       `blocks` <- block (block-sep block)* block-sep*
          block <- codeblock / (!"\n\n" !header 1)+
    `block-sep` <- "\n\n" "\n"*

      codeblock   <- code-start (!code-end 1)* code-end
     `code-start` <- "#" ("!"+)@codelevel code-name@code_c (!"\n" 1)* "\n"
       `code-end` <- "\n" "#" ("/")+@(#codelevel) code-name@(code_c)
                     (!"\n" 1)* (block-sep / "\n" / -1)
       `code-name`  <- (([a-z]/[A-Z]) ([a-z]/[A-Z]/[0-9]/"-"/"_")*)*

]]





local Doc = {}



return Peg(Doc_str)
