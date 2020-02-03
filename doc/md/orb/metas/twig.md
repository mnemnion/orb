# Twig


Every Node in Orb inherits from this common table.


For speed, we're going to copy everything from Node, rather than inheriting in
the usual sense.

```lua
local Node = require "espalier:espalier/node"
```
```lua
local Twig = {}

for k,v in next, Node do
   Twig[k] = v
end

Twig.__index = Twig
Twig.id = "twig"
```
```lua
return Twig
```
