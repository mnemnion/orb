# Knit module


 This is due for a complete overhaul.

```lua
local L = require "lpeg"

local s = require "singletons/status" ()
local a = require "singletons/anterm"
s.chatty = true
s.verbose = false

local pl_mini = require "orb:util/plmini"
local read, write, delete = pl_mini.file.read,
                            pl_mini.file.write,
                            pl_mini.file.delete


local knitter = require "orb:knit/knitter"

local Dir = require "orb:walk/directory"
local Path = require "orb:walk/path"
local File = require "orb:walk/file"
local walk = require "orb:walk/walk"

local Doc = require "orb:Orbit/doc"

```
## knitCodex(codex)

This is our new interface for knitting matters.


``knitCodex`` expects a codex which has been [cased](httk://) and
[spun](httk://).

```lua
local function knitDeck(deck)
    local dir = deck.dir
    local codex = deck.codex
    local orbDir = codex.orb
    local srcDir = codex.src
    -- #todo load .deck file here
    for i, sub in ipairs(deck) do
        knitDeck(sub)
    end
    for name, doc in pairs(deck.docs) do
        local knitted, ext = knitter:knit(doc)
        if knitted then
            -- add to srcs
            local srcpath = Path(name):subFor(orbDir, srcDir, ext)
            s:verb("knitted: " .. name)
            s:verb("into:    " .. tostring(srcpath))
            deck.srcs[srcpath] = knitted
            codex.srcs[srcpath] = knitted
        end

    end
    return deck.srcs
end

local function knitCodex(codex)
    local orb = codex.orb
    local src = codex.src
    s:chat("knitting orb directory: " .. tostring(orb))
    s:chat("into src directory: " .. tostring(src))
    knitDeck(orb)
    for name, src in pairs(codex.srcs) do
        walk.writeOnChange(name, src)
    end
end
knitter.knitCodex = knitCodex


return knitter
```
