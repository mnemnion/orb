# File

The File class is about to undergo an extensive rewrite.


Currently we use ``penlight`` to open and read from files, and we want to
switch to ``luv`` using coroutines and wrappers.


This will give us flexibility down the line and eliminates a dependency which
is duplicated with ``luv`` to a much greater degree of flexibility.





```lua
local uv = require "luv"

local Path = require "fs:path"
local lfs = require "lfs"
local pl_mini = require "orb:util/plmini"
local extension, basename = pl_mini.path.extension, pl_mini.path.basename
local isfile = pl_mini.path.isfile
```
```lua
local new
```
```lua
local function __tostring(file)
   return file.path.str
end
```
```lua
local File = {}
local __Files = {}
File.it = require "singletons/check"
```
```lua
function File.parentPath(file)
   return file.path:parentDir()
end
```
```lua
function File.exists(file)
   return isfile(file.path.str)
end
```
```lua
function File.basename(file)
   return basename(file.path.str)
end
```
```lua
function File.extension(file)
   return extension(file.path.str)
end
```
```lua
function File.read(file)
   local f = io.open(file.path.str, "r")
   local content = f:read("*a")
   f:close()
   return content
end
```

The following is crude but maybe good enough for orb.

```lua
function File.write(file, doc)
   local f = io.open(file.path.str, "w")
   f:write(tostring(doc))
   f:close()
end
```
```lua
local FileMeta = { __index = File,
                   __tostring = __tostring}

new = function (file_path)
   local file_str = tostring(file_path)
   -- #nb this is a naive and frankly dangerous guarantee of uniqueness
   -- and is serving in place of something real since filesystems... yeah
   if __Files[file_str] then
      return __Files[file_str]
   end

   local file = setmetatable({}, FileMeta)
   if type(file_path) == "string" then
      file.path = Path(file_path)
   elseif file_path.idEst == Path
      and not file_path.isDir then
      file.path = file_path
   end
   __Files[file_str] = file

   return file
end

```
```lua
File.idEst = new
return new
```
