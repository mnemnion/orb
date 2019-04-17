# Codex

A Codex is currently a directory in our Orb-style format.


We're trying to work our way into a proper database.


## Instance Fields

- docs:  Array keyed by full path name of file, and the spun-up Doc as
         the value.


- files:  Array keyed by full path name of file, and a string of the read file
          as the value. I think. #todo check


- srcs:  Array keyed by Path of file, and a string of the knit
         source files. This might also be a File; God what a mess.


- serve:  A [Watcher](httk://) for file changes.  Only present when
          initialized with ``orb serve``.


- root:  The root [deck](httk://) for the codex.


- orb:  The deck containing the source Orb files.


- src:  The deck containing the knit src files.


- lib:  The deck containing the lib files. #NB: In the process of phasing this
        out in favor of a database of modules.


- srcLib: The deck which is just a symlink of lib and I don't know what I was
          thinking when I thought this was a good idea. JFC.

```lua
local pl_file = require "pl.file"
local write = pl_file.write
```
```lua
local s = require "kore/status" ()
s.verbose = true

local Dir  = require "walk/directory"
local File = require "walk/file"
local Path = require "walk/path"
local Deck = require "walk/deck"
local ops  = require "walk/ops"

local knitter = require "knit/knitter"

local Watcher = require "femto/watcher"
```
```lua
local Codex = {}
Codex.__index = Codex
local __Codices = {} -- One codex per directory
```
## spin

The spin step is passed through to the Orb deck.


This needs to generalize on a per-file basis.


Currently spinning just loads files into the Deck(s).

```lua
function Codex.spin(codex)
   codex.orb:spin()
end
```
## serve

```lua
local function changer(codex)
   local function onchange(watcher, fname)
      local full_name = tostring(codex.orb) .. "/" .. fname
      print ("changed " .. full_name)
      if codex.docs[full_name] and full_name:sub(-4) == ".orb" then
         local doc = Doc(codex.files[full_name]:read())
         local knit_doc = knitter:knit(doc)
         local knit_name = tostring(codex.src) .. "/"
                           .. fname : sub(1, -5) .. ".lua"
         local written = write(knit_name, tostring(knit_doc))
         print("knit_doc is type " .. type   (knit_doc))
      else
         print("false")
      end
   end

   return onchange
end


local function renamer(codex)
   local function onrename(watcher, fname)
      print ("renamed " .. fname)
   end

   return onrename
end

function Codex.serve(codex)
   codex.server = Watcher { onchange = changer(codex),
                            onrename = renamer(codex) }
   codex.server(tostring(codex.orb))
end
```
### isACodex

  Used in our constructor to determine to what degree the local
directory fits the Codex format.  If it meets all the [critera](httk://)
then ``codex.codex`` is set to ``true``.


Any partial matches are added to the Codex as they are found.

```lua
local function isACodex(dir, codex)
   local isCo = false
   local orbDir, srcDir, libDir, srcLibDir = nil, nil, nil, nil
   codex.root = dir
   dir:getsubdirs()
   for i, sub in ipairs(dir.subdirs) do
      local name = sub:basename()
      if name == "orb" then
         s:verb("orb: " .. tostring(sub))
         orbDir = sub
         codex.orb = sub
      elseif name == "src" then
         s:verb("src: " .. tostring(sub))
         srcDir = Dir(sub)
         codex.src = sub
         srcDir:getsubdirs()
         for j, subsub in ipairs(sub.subdirs) do
            local subname = subsub:basename()
            if subname == "lib" then
               s:verb("src/lib: " .. tostring(subsub))
               srcLibDir = subsub
            end
         end
          --]]
      elseif name == "lib" then
         s:verb("lib: " .. tostring(sub))
         libDir = sub
         codex.lib = sub
      end
   end
   if orbDir and srcDir and libDir and srcLibDir then
      -- check equality of /lib and /src/lib
      codex.codex = true
   end
   return codex
end
```
```lua
local function new(dir)
   if type(dir) == "string" then
      dir = Dir(dir)
   end
   if __Codices[dir] then
      return __Codices[dir]
   end
   local codex = setmetatable({}, Codex)
   codex = isACodex(dir, codex)
   if codex.orb then
      codex.orb = Deck(codex, codex.orb)
   end
   codex.docs  = {}
   codex.files = {}
   codex.srcs  = {}
   return codex
end
```
```lua
Codex.idEst = new
return new
```
