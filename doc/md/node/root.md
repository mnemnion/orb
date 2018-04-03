# Root metatable


  We instantiate a new one of these for each parse.

### includes

```lua
local Node = require "node/node"
local u = require "util"

```
```lua
local R, r = u.inherit(Node)
```
```lua
local function new(Root, str)
  local root = setmetatable({}, R)
  root.str = str
  return root
end
```
```lua
return u.export(r, new)
```
