# Compiler


The ``compiler`` takes a knitted Skein and prepares artifacts for persistence
and further processing.


The lifecycle of artifacts from various programming languages diverges sharply
after preparing the sorcery file, and a lot of that is out of scope: while we
could shell out to ``make`` for C files, that presumes a lot about the destiny
of the artifact.


In order to provide this flexibility, ``compiler`` needs to be pluggable, so it
returns a table, which we might promote to an instance down the line.


For now, our urgent need is to get some Lua into the ``bridge.modules`` database
expediently, and in a way that's compatible with our existing toolchain.

```lua
local compiler = {}
```
#### imports

```lua
local sha512 = require "orb:compile/sha2" . sha3_512

local s = require "singletons/status" ()
s.verbose = false
```
#### sha(str)

Our sha returns 128 bytes, which is excessive, so let's truncate to 64:

```lua
local sub = assert(string.sub)
local function sha(str)
   return sub(sha512(str),1,64)
end
```
#### _moduleName(path, project)

This takes a Path and a string for the project and derives a plausible module
name from it.


This encodes certain assumptions which I would like to loosen, later.


Every time I work with directories I'm reminded what an awkward way to
organize information they are.  Yet here we are...

#Todo the weird_path -> good_path pipeline shouldn't be necessary, if we make
they should never make it here to begin with.

```lua
local function _moduleName(path, project)
   local mod = {}
   local inMod = false
   for i, v in ipairs(path) do
      if v == project then
         inMod = true
      end
      if inMod then
         if i ~= #path then
            table.insert(mod, v)
          else
             table.insert(mod, path:barename())
         end
      end
   end
   -- drop the bits of the path we won't need
   --- awful kludge fix
   local weird_path = table.concat(mod)
   local good_path = string.gsub(weird_path, "%.%_", "")
   local _, cutpoint = string.find(good_path, "/src/")
   local good_path = string.sub(good_path, cutpoint + 1)
   return good_path
end
```
