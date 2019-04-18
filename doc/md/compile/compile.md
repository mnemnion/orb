# Compile


The goal here is to make a single SQLite file containing all bytecode for
``bridge`` projects.


Eventually this can drive a general-purpose build system I guess. We've got
a long way to go with Orb before that's practical.


For now it just makes LuaJIT bytecode.

```lua
local loader = require "compile/loader"
local director = require "walk/directory"

local s = require "status" ()
s.verbose = true
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
### compileDeck(deck)

Compiles a deck to bytecode. The deck must be knitted first.


Returns ( ``true``, or ``false`` ), the number of errors, and an array of strings
representing all files which didn't compile.

```lua
local Compile = {}
local dump = string.dump

local function compileDeck(deck)
   local codex = deck.codex
   local complete, errnum, errs = true, 0, {}
   deck.bytecodes = deck.bytecodes or {}
   for _, subdeck in ipairs(deck) do
      local deck_complete, deck_errnum, deck_errs = compileDeck(subdeck)
      complete = complete and deck_complete
      errnum = errnum + deck_errnum
      splice(errs, nil, deck_errs)
   end
   for name, src in pairs(deck.srcs) do
      local bytecode, err = load(tostring(src), tostring(name))
      if bytecode then
         -- add to srcs
         local byte_str = dump(bytecode)
         codex.bytecodes[name] = byte_str
         deck.bytecodes[name] = byte_str
         s:verb("compiled: " .. tostring(name))
      else
        s:verb "error:"
        s:verb(err)
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

This is kind of senseless to be honest, we pass in the src deck and then
extract the codex from it and grab the src deck again.

```lua

function Compile.compileCodex(codex)
   return compileDeck(codex.orb)
end
```
```lua
return Compile
```
