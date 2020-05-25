





local L = require "lpeg"

local s = require "status:status" ()
local a = require "singletons/anterm"
s.chatty = true
s.verbose = false

local pl_mini = require "orb:util/plmini"
local read, write, delete = pl_mini.file.read,
                            pl_mini.file.write,
                            pl_mini.file.delete


local knitter = require "orb:knit/knitter"

local Dir = require "fs:directory"
local Path = require "fs:path"
local File = require "fs:file"
local walk = require "orb:walk/walk"

local Doc = require "orb:Orbit/doc"











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
            walk.writeOnChange(srcpath, knitted)
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
end
knitter.knitCodex = knitCodex


return knitter
