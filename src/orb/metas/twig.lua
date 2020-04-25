





local Node = require "espalier:espalier/node"
local a = require "anterm:anterm"
local Set = require "set:set"
local Codepoints = require "singletons:singletons/codepoints"









local Twig = {}

for k,v in next, Node do
   Twig[k] = v
end

Twig.__index = Twig
Twig.id = "twig"















local _select = Node.select

function Twig.select(twig, pred)
   if type(pred) == "function" then
      return _select(twig, pred)
   end
   local memo
   twig.__memo = twig.__memo or {}
   if twig.__memo[pred] then
      memo = twig.__memo[pred]
   else
      memo = {}
      for result in _select(twig, pred) do
         memo[#memo + 1] = result
      end
      twig.__memo[pred] = memo
   end
   local cursor = 0
   return function()
      cursor = cursor + 1
      if cursor > #memo then
         return nil
      end
      return memo[cursor]
   end
end









local md_special = Set {"\\", "`", "*", "_", "{", "}", "[", "]", "(", ")",
                        "#", "+", "-", ".", "!"}

function Twig.toMarkdown(twig)
   local points = Codepoints(twig:span())
   for i , point in ipairs(points) do
      if md_special[point] then
         points[i] = "\\" .. point
      end
   end
   return tostring(points)
end



return Twig
