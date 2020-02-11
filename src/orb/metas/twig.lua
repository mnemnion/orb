








local Node = require "espalier:espalier/node"
local a = require "anterm:anterm"



local Twig = {}

for k,v in next, Node do
   Twig[k] = v
end

Twig.__index = Twig
Twig.id = "twig"



function Twig.strExtra(twig)
   if twig.should_be then
      return a.red(twig.should_be)
   end
   return ""
end



return Twig
