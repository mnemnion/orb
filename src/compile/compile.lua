











local commit = require "orb:compile/commit"
local database = require "orb:compile/database"
local sha512 = require "orb:compile/sha2" . sha3_512

local s = require "singletons/status" ()
s.verbose = false








local sub = assert(string.sub)
local function sha(str)
   return sub(sha512(str),1,64)
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
   -- drop the bits of the path we won't need
   --- awful kludge fix
   local weird_path = table.concat(mod)
   local good_path = string.gsub(weird_path, "%.%_", "")
   local _, cutpoint = string.find(good_path, "/src/")
   local good_path = string.sub(good_path, cutpoint + 1)
   return good_path
end











local Compile = {}
local dump = string.dump
local splice = require "singletons/core" . splice
local lines = require "core/string" . lines
local gsub = assert(string.gsub)

local insert, concat = assert(table.insert), assert(table.concat)


local function compileDeck(deck)
   local codex = deck.codex
   local byte_size, str_size = 0, 0
   s:verb ("codex project is " .. codex.project)
   local complete, errnum, errs = true, 0, {}
   deck.bytecodes = deck.bytecodes or {}
   for _, subdeck in ipairs(deck) do
      local deck_complete, deck_errnum, deck_errs, s_s, b_s = compileDeck(subdeck)
      byte_size = byte_size + b_s
      str_size = str_size + s_s
      complete = complete and deck_complete
      errnum = errnum + deck_errnum
      splice(errs, nil, deck_errs)
   end
   for name, src in pairs(deck.srcs) do
      src = tostring(src)
      local bytecode, err = load (src,
                                  "@" .. _moduleName(name, codex.project))
      if bytecode then
         -- strip leading whitespace
         local stripped = {}
         for line in lines(src) do
            -- leading whitespace
            line = gsub(line, "^%s+", "")
            insert(stripped, line)
         end
         -- add to srcs
         local byte_str = concat(stripped, "\n")
         str_size = str_size + #byte_str
         byte_size = byte_size + #dump(bytecode)
         local byte_table = { binary = byte_str }
         --[[
         if byte_str == "" then
            s : halt "null byte string"
         end]]
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

   return complete, errnum, errs, str_size, byte_size
end

Compile.compileDeck = compileDeck






function Compile.compileCodex(codex)
   local complete, errnum, errs, str_size, byte_size = compileDeck(codex.orb)
   print ("total size of strings: " .. str_size)
   print ("total size of bytecodes: " .. byte_size)
   print ("ratio: " .. str_size / byte_size)
   commit.commitCodex(codex)
   return complete, errnum, errs
end



return Compile
