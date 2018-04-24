




























local Dir = require "walk/directory"
local s   = require "status" ()
s.verbose = true

local c   = require "core/color"
local cAlert = c.color.alert



local Deck = {}
Deck.__index = Deck
local __Decks = {}



-- ignore a few critters that can show up
local decIgnore = {".DS_Store", ".git"}

local function ignore(file)
   local willIgnore = false
   local basename = file:basename()
   for _, str in ipairs(decIgnore) do
      willIgnore = willIgnore or basename == str
   end
   return willIgnore
end
















local new

function Deck.case(deck)
   s:verb("dir: " .. tostring(deck.dir))
   local dir = deck.dir
   local codex = deck.codex
   local basename = dir:basename()
   assert(dir.idEst == Dir, "dir not a directory")
   local codexRoot = codex.root:basename()
   s:verb("root: " .. tostring(codex.root) .. " base: " ..tostring(codexRoot))
   local subdirs = dir:getsubdirs()
   s:verb("  " .. "# subdirs: " .. #subdirs)
   for i, sub in ipairs(subdirs) do
      s:verb("  - " .. sub.path.str)
      deck[i] = new(codex, sub)
   end
   local files = dir:getfiles()
   s:verb("  " .. "# files: " .. #files)
   for i, file in ipairs(files) do
      if not ignore(file) then
         local name = file:basename()
         if name == ".deck" then
            s:ver()
            deck.dotDeck = file
         elseif #file:extension() > 1 then
            name = string.sub(name, 1, - #file:extension() - 1)
         end
         if name == basename then
            s:verb("  ~ " .. name)
            deck.eponym = file
         end
      end
   end

   s:verb("#deck is : " .. #deck)
   return codex
end



new = function (codex, dir)
   if type(dir) == "string" then
      dir = Dir(dir)
   end
   if __Decks[dir] then
      return __Decks[dir]
   end
   local deck = setmetatable({}, Deck)
   deck.dir = dir
   deck.codex = codex
   Deck.case(deck)
   return deck
end




Deck.idEst = new
return new
