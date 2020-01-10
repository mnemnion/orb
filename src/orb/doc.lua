


















local Peg = require "espalier:peg"
local Node = require "espalier:node"




local Doc_str = [[
            doc <- first-section* section+
`first-section` <- "placeholder" ; this rule may be tricky to get right
        section <- header (block-sep / "\n" / -1) blocks*
         header <- "*"+ " " header-line
    header-line <- (!"\n" 1)* ; this is one we sub-parse
         blocks <- block (block-sep block)* block-sep*
          block <- (!"\n\n" !header 1)+
    `block-sep` <- "\n\n" "\n"*
]]





local Doc = {}



return Peg(Doc_str)
