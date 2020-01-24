



local Peg = require "espalier:espalier/peg"
local metafn = require "espalier:espalier/metafn"



local header_str = [[
     header  <-  " "* level head-line
      level  <-  "*"+
  head-line  <-  (" " header-text) / -1
  header-text <- 1*
]]



local header_grammar = Peg(header_str)




return metafn(header_grammar.parse, "header-nomatch")
