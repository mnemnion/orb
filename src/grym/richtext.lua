









local Node = require "node"

local u = require "util"











local Lit, lit = u.inherit(Node)







function Lit.toMarkdown(literal)
  return "`" .. literal:toValue() .. "`"
end





local Ita = u.inherit(Node)

function Ita.toMarkdown(italic)
  return "*" .. italic:toValue():gsub("*", "\\*") .. "*"
end





local Bold = u.inherit(Node)

function Bold.toMarkdown(bold)
  return "**" .. bold:toValue():gsub("*", "\\*") .. "**"
end







return { literal = Lit, 
     italic  = Ita,
     bold    = Bold }
