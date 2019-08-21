# Deck


A Deck is a way of corresponding the various incarnations of a source file
on a per-directory basis.


This is currently limited to Orb and sorcery files, but will also include
weaves and bytecode (bytecode I'm working on at present).


The reason weaves haven't been incorporated is simply that weaving has never
been updated to use the new abstractions, and as I intend to (mostly) replace
translation to Markdown with translation to HTML, this is fine for now.


#### a digression on literate programming and file correspondence

  At some later point in the evolution of this tool, I intend to break the
one-to-one correspondence of Orb files with sorcery.  This is one of the
promising aspects of literate programming, but to achieve this in a way which
is _useful to the programmer_ I will have to make considerable progress on the
rest of the tools.


The bare minimum I'll need here will be source mapping, so that the runtime
may present to the user a correspondence between an error message and the
actual source code, which is, let us remember, the Orb files.


This is one of the reasons, in my opinion, that literate programming never
caught on.  It is liberating to be able to use macros and the like to write
the code in a reader's expected order, but tedious and taxing to have to
figure out where an error is to be found in the actual code.


This taxation comes at the worst possible time, when all of the writer's
energy is being channeled into debugging.  I've been known to lose my train of
thought just between seeing an error line and tabbing over to my editor.


## Instance fields.

Decks have sub decks, if any, in the array portion of their table.


- dir:  A Directory object corresponding to the Deck.


- codex: The Codex of which this directory is a part. A given Deck must be
         created with a Codex.


- docs:  A map, the keys of which are full path names, and the values of which
         are Doc objects.


- srcs:  A map, keys are full path names, values are knit sorcery files.


- eponym:  A Doc which has ``{basename}.org``, that is, the basename of the
           deck, will be added to ``deck.eponym``.


           I don't appear to use this, at present.  But it's harmless, at
           least.

```lua
local s   = require "status" ()
s.verbose = false
s.chatty  = true

local c   = require "singletons/color"
local cAlert = c.color.alert

local Dir = require "walk/directory"
local Doc = require "Orbit/doc"
local Node = require "espalier/node"
```
```lua
local Deck = {}
Deck.__index = Deck
local __Decks = {}
```
```lua
-- ignore a few critters that can show up
local decIgnore = {".DS_Store", ".git", ".orbback"}

local function ignore(file)
   local willIgnore = false
   local basename = file:basename()
   for _, str in ipairs(decIgnore) do
      willIgnore = willIgnore or basename == str
   end
   return willIgnore
end
```
## spin(deck)

If we're going to be lazy, this is where we should do it!


Right now, we're going to load all Docs into memory, willy nilly.

```lua
local function spin(deck)
   local err = {}
   local dir = deck.dir
   local codex = deck.codex
   for _, subdeck in ipairs(deck) do
      spin(subdeck)
   end
   local files = dir:getfiles()
   for _, file in ipairs(files) do
      if not ignore(file) then
         local doc = Doc(file:read())
         if doc.id and doc.id == "doc" then
            deck.docs[file.path.str] = doc
            codex.docs[file.path.str] = doc
            codex.files[file.path.str] = file
         else
            s:complain("no doc",
                       tostring(file) .. " doesn't generate a doc")
         end
      end
   end
   return deck, err
end

Deck.spin = spin
```
## case(deck)

  Casing is what we call gathering information about a deck, its subdecks,
and associated files.


Casing a deck will cause its subdecks to be cased also, recursively. This is
where we will add inode comparison to keep from following cyclic references,
since it's what draws directory attributes out of the filesystem into memory.


After casing a Deck is ready to be [spun](httk://).

```lua
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
         if #file:extension() > 1 then
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
```
### __tostring

```lua
function Deck.__tostring(deck)
   return deck.dir.path.str
end
```
```lua
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
   deck.docs  = {}
   deck.srcs  = {}
   Deck.case(deck)
   return deck
end
```
```lua
Deck.idEst = new
return new
```
