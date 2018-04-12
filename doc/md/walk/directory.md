# Directory


``bridge`` is going to have a certain attitude toward directories. 


The ``orb`` directory module will emulate and prototype that attitude. 

```lua
local Dir = setmetatable({}, {__index = Dir,
                isDir   = Dir})
```
```lua
function new(Dir, path)
  local dir = setmetatable({}, Dir)
  dir.path = path
  return dir
end
```
```lua
return setmetatable({}, {__call = new, __index = Dir})
```