# Compiler


The `compiler` takes a knitted Skein and prepares artifacts for persistence
and further processing\.

The lifecycle of artifacts from various programming languages diverges sharply
after preparing the sorcery file, and a lot of that is out of scope: while we
could shell out to `make` for C files, that presumes a lot about the destiny
of the artifact\.

In order to provide this flexibility, `compiler` needs to be pluggable, so it
returns a table, which we might promote to an instance down the line\.

For now, our urgent need is to get some Lua into the `bridge.modules` database
expediently, and in a way that's compatible with our existing toolchain\.

```lua
local compiler, compilers = {}, {}
compiler.compilers = compilers
```


#### imports

```lua
local sha512 = require "orb:compile/sha2" . sha3_512

local s = require "status:status" ()
s.verbose = false
```


#### sha\(str\)

Our sha returns 128 bytes, which is excessive, so let's truncate to 64:

```lua
local sub = assert(string.sub)
local function sha(str)
   return sub(sha512(str),1,64)
end
```


#### \_moduleName\(path, project\)

This takes a Path and a string for the project and derives a plausible module
name from it\.

This encodes certain assumptions which I would like to loosen, later\.

Every time I work with directories I'm reminded what an awkward way to
organize information they are\.  Yet here we are\.\.\.

\#Todo
sure that stupid Dropbox and Time Machine artifacts don't end up in our
Codex to begin with\.

Hmm\. Actually a file watcher has to guard against those as well\.  Point being,
they should never make it here to begin with\.

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


### compilers\.lua\(skein\)

I'm not convinced this is the right function signature, but, adelante\.

```lua
function compilers.lua(skein)
   local project = skein.lume.project
   skein.compiled = skein.compiled or {}
   local compiled = skein.compiled
   local path = skein.knitted.lua.path
   local src = skein.knitted.lua
   local mod_name = _moduleName(path, project)
   local bytecode, err = load (tostring(src), "@" .. mod_name)
   if bytecode then
      -- add to srcs
      local byte_str = tostring(src) -- #todo: parse and strip
      local byte_table = {binary = byte_str}
      byte_table.hash = sha(byte_str)
      byte_table.name = mod_name
      byte_table.err = false
      compiled.lua = byte_table
      s:verb("compiled: " .. project .. ":" .. byte_table.name)
   else
      s:chat "error:"
      s:chat(err)
      compiled.lua = { err = err }
   end
end
```


### compiler:compile\(skein\)

Simply goes through all the Scrolls in the `knitted` table of the Skein, and
compiles them if there is an appropriate compiler in `compile.compilers`\.

Which, if the scroll is a Lua scroll, there is\.

```lua
function compiler.compile(compiler, skein)
   for extension, scroll in pairs(skein.knitted) do
      if compiler.compilers[extension] then
         compiler.compilers[extension](skein)
      end
   end
end
```

```lua
return compiler
```
