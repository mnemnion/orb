











local loader = require "compile/loader"

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










function Compile.compileCodex(codex)
   loader.load()
   return compileDeck(codex.orb)
end



return Compile
