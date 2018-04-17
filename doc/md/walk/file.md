# File


```lua
local Path = require "walk/path"
local Dir  = require "walk/directory"
local lfs = require "lfs"
local pl_path = require "pl.path"
local isfile = pl_path.isfile
```
```lua
local function __tostring(file)
   return file.path.str
end
```
```lua
local File = {}
local __Files = {}
File.it = require "core/check"
```
```lua
function File.exists(file)
   return isfile(file.path.str)
end
```
```lua

local FileMeta = { __index = File,
                   __tostring = __tostring}

local function new(file_path)
   file_str = tostring(file_path)
   if __Files[file_str] then
      return nil, "won't make the same file twice"
   end

   local file = setmetatable({}, FileMeta)
   if type(file_path) == "string" then
      file.path = Path(file_path)
   elseif file_path.idEst == Path
      and not file_path.isDir then
      file.path = file_path
   end
   __Files[file_str] = true

   return file
end

```
```lua
File.idEst = new
return new
```
