





local Node = require "espalier:espalier/node"
local a = require "anterm:anterm"
local Set = require "set:set"
local Codepoints = require "singletons:singletons/codepoints"
local Phrase = require "singletons:singletons/phrase"









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











function Twig.bustCache(twig)
   twig.__memo = nil
end













local md_special = Set {"\\", "`", "*", "_", "{", "}", "[", "]", "(", ")",
                        "#", "+", "-", ".", "!"}

function Twig.toMarkdown(twig, scroll)
   if #twig == 0 then
      local points = Codepoints(twig:span())
      for i , point in ipairs(points) do
         if md_special(point) then
            points[i] = "\\" .. point
         end
      end
      scroll:add(tostring(points))
      return tostring(points)
   else
      local phrase = ""
      for _, sub_twig in ipairs(twig) do
         phrase = phrase .. sub_twig:toMarkdown(scroll)
      end
      return phrase
   end
end











local function _escapeHtml(span)
   -- stub
   return span
end

function Twig.toHtml(twig, skein)
   local phrase = '<span class="' .. twig.id .. Phrase '">'
   if #twig == 0 then
      phrase = phrase .. _escapeHtml(twig:span())
   else
      for _, sub_twig in ipairs(twig) do
         phrase = phrase .. sub_twig:toHtml(skein)
      end
   end
   return phrase .. "</span>"
end










function Twig.nullstring()
   return ""
end



return Twig
