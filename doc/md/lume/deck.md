# Deck


  A Deck is a meta\-directory, cross referenced between source, sorcery, and
weaves\.

```lua
local s   = require "status:status" ()
s.verbose = false
s.chatty  = true

local Dir = require "fs:fs/directory"
```



```lua
local new;

local Deck = {}
Deck.__index = Deck
local __Decks = setmetatable({}, { __mode = "kv" })
```

```lua
-- ignore a few critters that can show up
local decIgnore = {".DS_Store", ".git"}

local function ignore(file)
   local willIgnore = false
   local basename = file:basename()
   for _, str in ipairs(decIgnore) do
      willIgnore = willIgnore or basename == str
   end
   -- Goddammit Dropbox
   willIgnore = willIgnore or (string.find(tostring(file), "%.%_") ~= nil)
   return willIgnore
end
```


## case\(deck\)

  Casing the Deck draws its sub\-decks into memory, and pushes all the files
in the orb directory onto the Lume shuttle\.

```lua
local new

local function case(deck)
   s:verb("dir: " .. tostring(deck.dir))
   local dir = deck.dir
   local lume = deck.lume
   local basename = dir:basename()
   assert(dir.idEst == Dir, "dir not a directory")
   local lumeRoot = lume.root:basename()
   s:verb("root: " .. tostring(lume.root) .. " base: " ..tostring(lumeRoot))
   local subdirs = dir:getsubdirs()
   s:verb("  " .. "# subdirs: " .. #subdirs)
   for i, sub in ipairs(subdirs) do
      s:verb("  - " .. sub.path.str)
      deck[i] = new(lume, sub)
   end
   local files = dir:getfiles()
   s:verb("  " .. "# files: " .. #files)
   for i, file in ipairs(files) do
      if not ignore(file) then
         lume.shuttle:push(file)
         --[[not using eponyms, if it doesn't come up, delete this
         local name = file:basename()
         if #file:extension() > 1 then
            name = string.sub(name, 1, - #file:extension() - 1)
         end
         if name == basename then
            s:verb("  ~ " .. name)
            deck.eponym = file
         end
         --]]
      end
   end

   s:verb("#deck is : " .. #deck)
   return lume
end

Deck.case = case
```

```lua
new = function (lume, dir)
   if type(dir) == "string" then
      dir = Dir(dir)
   end
   s:verb("directory: %s", tostring(dir))
   if __Decks[dir] then
      return __Decks[dir]
   end
   local deck = setmetatable({}, Deck)
   deck.dir = dir
   deck.lume = lume
   deck.files  = {}
   case(deck)
   return deck
end
```


```lua
Deck.idEst = new
return new
```
