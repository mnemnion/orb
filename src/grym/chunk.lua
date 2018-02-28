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
local util = require "../lib/util"
local freeze = util.freeze


-- Metatable for Chunks

local C = setmetatable({}, { __index = Node })
C.__index = C

C.__tostring = function(chunk) 
    return "Chunk"
end

-- Adds a .val field which is the union of all lines.
-- Useful in visualization. 
function C.toValue(chunk)
    chunk.val = ""
    for _,v in ipairs(chunk.lines) do
        chunk.val = chunk.val .. v .. "\n"
    end
end


-- Constructor/module

local c = {}

local function new(Chunk, lines)
    local chunk = setmetatable({}, C)
    chunk.lines = {}
    if (lines) then 
        if type(lines) == "string" then
            chunk.lines[1] = lines
        elseif type(lines) == "table" then
            for i, v in ipairs(lines) do
                chunk.lines[i] = v
            end
        else
            freeze("Error: in Chunk.new type of `lines` is " .. type(lines))
        end
    end

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


-- Chunks a Block.
--
-- This is a moderately complex state machine, which
-- works on a line-by-line basis with some lookahead.
--
-- Prose line: if preceded by at least one blank line,
-- make a new chunk, otherwise append to existing chunk.
--
-- List line: new chunk unless previous line is also list,
-- in which case append. 
--
-- Table line: same as list.
--
-- Tag line: a tag needs to cling, so we need to check the
-- number of blank lines before and after a tag line, if any.
-- If even, a tag line clings down.
--
-- Code block: These actually musy be guarded against in the 
-- first pass, because code structured like a header line has 
-- to be assigned to a code block, not introduce a spurious 
-- header. 
-- 
-- This is itself tricky because, to fulfill our promise of an
-- error-free format, we need to react to unbalanced documents,
-- in which a `#!` has no matching `#/`.  In this case the leading
-- `#!` line is simple prose and we must re-parse the rest of the
-- document accordingly. 
-- 
-- This isn't a routine we want to code twice, so bad code fences need
-- to be pre-treated to escape further attention. 
--
-- - #params
--   - block: the block
--
-- returns: the same block, filled in with chunks

function c.chunk(block)
    if block.header then io.write(block[1].line .. "\n") end
    -- Every block gets at least one chunk, which may be empty.
    local latest = new(nil, nil) -- current chunk
    -- There is always a header at [1], though it may be nil
    block[2] = latest
    local back_blanks = 0
    for i = 1, #block.lines do
        local v = block.lines[i]
        if v == "" then 
            -- increment back blanks for clinging subsequent lines
            back_blanks = back_blanks + 1
            -- start a new chunk
            local new_chunk = new(nil, nil)
            block[#block + 1] = new_chunk
            latest = new_chunk
        else
            local structure, id = structureOrProse(v)
            if structure then
                -- This is the tricky part
                io.write("  " .. id .. "\n")
            else
                latest.lines[#latest.lines + 1] = v
            end
        end
        
    end
    return block
end

c["__call"] = new
c["__index"] = c

return setmetatable({}, c)









