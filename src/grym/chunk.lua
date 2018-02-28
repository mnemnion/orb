-- * Chunk module
--
--   A Chunk is the container for the next level of granularity below
-- a Block. A given Block has a Header and zero or more Chunks.
--
-- A paragraph of prose is the simplest chunk, and the default. A list with
-- a tag line is a chunk also, as is a table.  Most importantly for our short
-- path, code blocks are chunks also.
--
-- Chunking needs to identify when it has structure, and when prose, on a 
-- line-by-line basis.  It must also apply the cling rule to make sure that
-- e.g. tags are part of the chunk indicated by whitespacing. 
-- 
-- Chunking need not, and mostly should not, parse within structure or prose.
-- These categories are determined by the beginning of a line, making this
-- tractable. 
-- 
-- The cling rule requires lookahead. LPEG is quite capable of this, as is 
-- packrat PEG parsing generally.  In the bootstrap implementation, we will
-- parse once for ownership, again (in the `lines` array of each Block) for
-- chunking, and a final time to parse within chunks. 
--
-- Grimoire is intended to work, in linear time, as a single-pass PEG
-- grammar.  Presently (Feb 2018) I'm intending to prototype that with 
-- PEGylator and port it to `hammer` with a `quipu` back-end. 
--

local L = require "lpeg"

local Node = require "peg/node"

local m = require "grym/morphemes"


-- Metatable for Chunks

local C = setmetatable({}, { __index = Node })
C.__index = C

C.__tostring = function(chunk) 
    return "Chunk"
end


-- Constructor/module

local c = {}

local function new(Chunk, lines)
    local chunk = setmetatable({}, C)
    chunk.lines = lines
    chunk.id = "chunk"
    return chunk
end


-- Sorts lines into structure and prose.
-- 
-- - line : taken from block.lines
--
-- - returns: 
--        1. true for structure, false for prose
--        2. id of structure line or "" for prose
--
local function structureOrProse(line)
    if L.match(m.tagline_p, line) then
        return true, "tagline"
    elseif L.match(m.listline_p, line) then
        return true, "listline"
    elseif L.match(m.tableline_p, line) then
        return true, "tableline"
    end
    return false, ""
end


-- Chunks a Block
-- 
-- block: the block
--
-- returns: the same block, filled in with chunks

function c.chunk(block)
    io.write(block[1].line .. "\n")
    for i = 1, #block.lines do
        local v = block.lines[i]
        local phrase = ""
        if v == "" then 
            phrase = "blank\n"
        end
        local structure, id = structureOrProse(v)
        if structure then
            phrase = "  " .. id .. "\n"
        elseif phrase == "" then
            phrase = "prose\n"
        end
        io.write(phrase)
    end
    return {}
end

c["__call"] = new
c["__index"] = c

return setmetatable({}, c)









