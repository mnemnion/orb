









local Node = require "espalier/node"

local u = {}
function u.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end
function u.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
end

local L = require "lpeg"











local Lit, lit = u.inherit(Node)















function Lit.toMarkdown(literal)
   return "``" .. literal:toValue() .. "``"
end





local Ita = u.inherit(Node)

function Ita.toMarkdown(italic)
   return "_" .. italic:toValue():gsub("_", "\\_") .. "_"
end





local Bold = u.inherit(Node)

function Bold.toMarkdown(bold)
   return "**" .. bold:toValue():gsub("*", "\\*") .. "**"
end












local Interpol = u.inherit(Node)

function Interpol.toMarkdown(interpol)
   return interpol:toValue()
end







return { literal = Lit,
       italic  = Ita,
       bold    = Bold,
       interpolated = Interpol }
