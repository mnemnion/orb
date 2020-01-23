



local Peg = require "espalier:espalier/peg"



local header_str = [[
     header  <-  level head-line
      level  <-  "*"+
  head-line  <-  (" " header-text) / -1
  header-text <- 1*
]]



local header_grammar = Peg(header_str)



local Header = function(t)
   assert(type(t.str) == "string")
   assert(type(t.first) == "number")
   assert(type(t.last) == "number")
   local match = header_grammar(t.str, t.first, t.last)
   return match
end



return Header
