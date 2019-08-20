# Knit module


 This is due for a complete overhaul.

```lua
local L = require "lpeg"

local s = require "status" ()
local a = require "ansi"
s.chatty = true
s.verbose = false

local pl_mini = require "util/plmini"
local read, write, delete = pl_mini.file.read,
                            pl_mini.file.write,
                            pl_mini.file.delete


local knitter = require "knit/knitter"

local Dir = require "walk/directory"
local Path = require "walk/path"
local File = require "walk/file"

local Doc = require "Orbit/doc"
local Path = require "walk/path"

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
    return srcs
end

local function writeOnChange(out_file, newest)
    newest = tostring(newest)
    out_file = tostring(out_file)
    local current = read(tostring(out_file))
    -- If the text has changed, write it
    if newest ~= current then
        s:chat(a.green("  - " .. tostring(out_file)))
        write(out_file, newest)
        return true
    -- If the new text is blank, delete the old file
    elseif current ~= "" and newest == "" then
        s:chat(a.red("  - " .. tostring(out_file)))
        delete(out_file)
        return false
    else
    -- Otherwise do nothing

        return nil
    end
end

local function knitCodex(codex)
    local orb = codex.orb
    local src = codex.src
    s:chat("knitting orb directory: " .. tostring(orb))
    s:chat("into src directory: " .. tostring(src))
    knitDeck(orb, src)
    for name, src in pairs(codex.srcs) do
        writeOnChange(name, src)
    end
end
knitter.knitCodex = knitCodex


return knitter
```
