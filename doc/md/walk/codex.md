# Codex

Now that we have some abstractions over the parts of a Codex,
let's write a class that's singlehandedly responsible for them.

```lua
local s = require "core/status" ()
s.verbose = true
local walk = require "walk"
local Dir, File, Path = walk.Dir, walk.Path, walk.File
```
```lua
local Codex = {}
```
```lua
local function isACodex(dir)
   local isCo = false
   local orbDir, srcDir, libDir, srcLibDir = nil, nil, nil, nil
   dir:getsubdirs()
   for i, sub in ipairs(dir.subdirs) do
      local name = sub:basename()
      if name == "orb" then
         s:verb("orb: " .. tostring(sub))
         orbDir = sub
      elseif name == "src" then
         s:verb("src: " .. tostring(sub))
         srcDir = Dir(sub)
         s:verb("idEst srcDir: " .. tostring(srcDir.idEst == Dir))
         srcDir:getsubdirs()
         for j, subsub in ipairs(sub.subdirs) do
            local subname = subsub:basename()
            if subname == "lib" then
               s:verb("src/lib: " .. tostring(subsub))
               subLibDir = subsub
            end
         end
          --]]
      elseif name == "lib" then
         s:verb("lib: " .. tostring(sub))
         libDir = sub
      end
   end
   if orbDir and srcDir and libDir and subLibDir then
      -- check equality of /lib and /src/lib
      isCo = true
   end
   return isCo
end

return isACodex -- shim
```
