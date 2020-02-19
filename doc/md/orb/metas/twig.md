# Twig


Every Node in Orb inherits from this common table.

```lua
local Node = require "espalier:espalier/node"
local a = require "anterm:anterm"
```
## Twig Module

For speed, we're going to copy everything from Node, rather than inheriting in
the usual sense.

```lua
local Twig = {}

for k,v in next, Node do
   Twig[k] = v
end

Twig.__index = Twig
Twig.id = "twig"
```
```lua
function Twig.strExtra(twig)
   if twig.should_be then
      return a.red(twig.should_be)
   end
   return ""
end
```
### Twig:select(pred)

Every call to ``select`` has to iterate the entire Node.


For some of the algorithms we've contemplated, that could get pretty
expensive.  In addition, the structure of an already-parsed Node may be
mutated somewhat, but at least the ``id`` field will remain consistent by the
time that parsing is complete.


So we'll handle this by memoizing selections that are based on strings.

```lua
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
```
```lua
return Twig
```
