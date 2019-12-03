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


- bytecodes: Array indexted by Path of file, value is a string that is a dump
             of the bytecode of the compiled sorcery.


- serve:  A [Watcher](httk://) for file changes.  Only present when
          initialized with ``orb serve``.


- root:  The root [deck](httk://) for the codex.


- orb:  The deck containing the source Orb files.


- src:  The deck containing the knit src files.


```lua
local pl_mini = require "orb:util/plmini"
local write = pl_mini.file.write
```
```lua
local s = require "singletons/status" ()
s.verbose = true

local Dir  = require "orb:walk/directory"
local File = require "orb:walk/file"
local Path = require "orb:walk/path"
local Deck = require "orb:walk/deck"
local ops  = require "orb:walk/ops"
local git_info = require "orb:util/gitinfo"

local knitter = require "orb:knit/knitter"

local Watcher = require "helm:watcher"
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
### buildCodex

Puts together a codex for a given project

```lua
local function buildCodex(dir, codex)
   local isCo = false
   local orbDir, srcDir, libDir, srcLibDir = nil, nil, nil, nil
   local docDir, docMdDir, docDotDir, docSvgDir = nil, nil, nil, nil
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
         -- #deprecated
         for j, subsub in ipairs(sub.subdirs) do
            local subname = subsub:basename()
            if subname == "lib" then
               s:verb("src/lib: " .. tostring(subsub))
               srcLibDir = subsub
            end
         end
          --]]
      -- #deprecated we will be removing lib from consideration.
      elseif name == "lib" then
         s:verb("lib: " .. tostring(sub))
         libDir = sub
         codex.lib = sub
      elseif name == "doc" then
         s:verb("doc: " .. tostring(sub))
         docDir = sub
         codex.doc = sub
         docDir:getsubdirs()
         for j, subsub in ipairs(sub.subdirs) do
            local subname = subsub:basename()
            if subname == "md" then
               s:verb("doc/md: " .. tostring(subsub))
               docMdDir = subsub
               codex.docMd = subsub
            elseif subname == "dot" then
               s:verb("doc/dot: " .. tostring(subsub))
               docDotDir = subsub
               codex.docDot = subsub
            elseif subname == "svg" then
               s:verb("doc/svg: " .. tostring(subsub))
               docSvgDir = subsub
               codex.docSvg = subsub
            end
         end
      end
   end

   if orbDir and srcDir and libDir and srcLibDir then
      codex.codex = true
   end
   return codex
end
```
### Codex(dir)

Makes a codex given a directory, in string or Path form.

#NB: the Path and everything which depends on it was a major blunder.  It's
corresponding to the root of the project. Wish me luck.

```lua
local function new(dir)
   if type(dir) == "string" then
      dir = Dir(dir)
   end
   if __Codices[dir] then
      return __Codices[dir]
   end
   local codex = setmetatable({}, Codex)
   codex = buildCodex(dir, codex)
   codex.project = dir.path[#dir.path] -- hmmm?
   if codex.orb then
      codex.orb = Deck(codex, codex.orb)
   end
   codex.git_info = git_info(tostring(dir))
   codex.docs  = {}
   codex.files = {}
   codex.srcs  = {}
   codex.docMds = {}
   codex.docSvgs = {}
   codex.docDots = {}
   -- codex.docHTMLs = {} #todo

   codex.bytecodes = {}
   return codex
end
```
```lua
Codex.idEst = new
return new
```
