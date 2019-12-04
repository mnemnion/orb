# Compile


The goal here is to make a single SQLite file containing all bytecode for
``bridge`` projects.


Eventually this can drive a general-purpose build system I guess. We've got
a long way to go with Orb before that's practical.


For now it just makes LuaJIT bytecode.

```lua
local loader = require "orb:compile/database"

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
#### splice(tab, index, into)

This is borrowed from ``femto.core`` and should be replaced with it once I'm
finally done sorting everything into a database

#todo replace with =femto.core=
compatible with existing functions and method syntax.


if ``index`` is nil, the contents of ``into`` will be inserted at the end of
``tab``

```lua
local insert = table.insert

local sp_er = "table<core>.splice: "
local _e_1 = sp_er .. "$1 must be a table"
local _e_2 = sp_er .. "$2 must be a number"
local _e_3 = sp_er .. "$3 must be a table"

local function splice(tab, idx, into)
   assert(type(tab) == "table", _e_1)
   assert(type(idx) == "number" or idx == nil, _e_2)
   if idx == nil then
      idx = #tab + 1
   end
   assert(type(into) == "table", _e_3)
    idx = idx - 1
    local i = 1
    for j = 1, #into do
        insert(tab,i+idx,into[j])
        i = i + 1
    end
    return tab
end
```
#### _moduleName(path, project)

This takes a Path and a string for the project and derives a plausible module
name from it.


This encodes certain assumptions which I would like to loosen, later.


Every time I work with directories I'm reminded what an awkward way to
organize information they are.  Yet here we are...

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
### compileDeck(deck)

Compiles a deck to bytecode. The deck must be knitted first.


Returns ( ``true``, or ``false`` ), the number of errors, and an array of strings
representing all files which didn't compile.

```lua
local Compile = {}
local dump = string.dump

local function compileDeck(deck)
   local codex = deck.codex
   s:verb ("codex project is " .. codex.project)
   local complete, errnum, errs = true, 0, {}
   deck.bytecodes = deck.bytecodes or {}
   for _, subdeck in ipairs(deck) do
      local deck_complete, deck_errnum, deck_errs = compileDeck(subdeck)
      complete = complete and deck_complete
      errnum = errnum + deck_errnum
      splice(errs, nil, deck_errs)
   end
   for name, src in pairs(deck.srcs) do
      local bytecode, err = load (tostring(src),
                                  "@" .. _moduleName(name, codex.project))
      if bytecode then
         -- add to srcs
         local byte_str = dump(bytecode)
         local byte_table = {binary = byte_str}
         if byte_str == "" then
            s : halt "null byte string"
         end
         byte_table.hash = sha(byte_str)
         byte_table.name = _moduleName(name, codex.project)
         codex.bytecodes[name] = byte_table
         deck.bytecodes[name] = byte_table
         s:verb("compiled: " .. codex.project .. ":" .. byte_table.name)
      else
         s:chat "error:"
         s:chat(err)
         complete = false
         errnum = errnum + 1
         errs[#errs + 1] = tostring(name)
      end
   end
   return complete, errnum, errs
end

Compile.compileDeck = compileDeck
```
### Compile.compileCodex(codex)

```lua

local uv = require "luv"
function Compile.compileCodex(codex)
   local complete, errnum, errs = compileDeck(codex.orb)
   local conn = loader.commitCodex(loader.open(), codex)
   -- set up an idler to close the conn, so that e.g. busy
   -- exceptions don't blow up the hook
   local close_idler = uv.new_idle()
   close_idler:start(function()
      local success = pcall(conn.close, conn)
      if not success then
        return nil
      else
        close_idler:stop()
        uv.stop()
      end
   end)
   uv.run "default"
   return complete, errnum, errs
end
```
```lua
return Compile
```
