











local loader = require "compile/loader"

local sha = require "sha3" . sha512

local s = require "status" ()
s.verbose = true
















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
   -- drop a bunch of extraneous detail
   table.remove(mod, 1)
   table.remove(mod, 1)
   table.remove(mod, 1)
   table.remove(mod, 1)
   return table.concat(mod)
end











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
      local bytecode, err = load(tostring(src), tostring(name))
      if bytecode then
         -- add to srcs
         local byte_str = dump(bytecode)
         local byte_table = {binary = byte_str}
         byte_table.hash = sha(byte_str)
         byte_table.name = _moduleName(name, codex.project)
         codex.bytecodes[name] = byte_table
         deck.bytecodes[name] = byte_table
         --s:verb("compiled: " .. tostring(name))
         --s:verb("sha512: " .. byte_table.hash)
         s:verb("compiled: " .. codex.project .. ":" .. byte_table.name)
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










function Compile.compileCodex(codex)
   loader.load()
   return compileDeck(codex.orb)
end



return Compile
