





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









































































local md_special = Set {"\\", "`", "*", "_", "{", "}", "[", "]", "(", ")",
                        "#", "+", "-", ".", "!"}

function Twig.toMarkdown(twig, scroll, skein)
   if #twig == 0 then
      local points = Codepoints(twig:span())
      for i , point in ipairs(points) do
         if md_special(point) then
            points[i] = "\\" .. point
         end
      end
      scroll:add(tostring(points))
   else
      for _, sub_twig in ipairs(twig) do
         sub_twig:toMarkdown(scroll, skein)
      end
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

