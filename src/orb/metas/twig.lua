








local Node = require "espalier:espalier/node"



local Twig = {}

for k,v in next, Node do
   Twig[k] = v
end

Twig.__index = Twig
Twig.id = "twig"



return Twig
