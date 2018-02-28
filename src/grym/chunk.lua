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
-- First off, we have a Header at [1], and may have one or 
-- more Blocks. The Chunks go between the Header and the remaining
-- Blocks, so we have to lift them and append after chunking.
-- 
-- Next, we parse the lines, thus:
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
    if block.header then 
        io.write(block[1].line .. "\n")
    else
        io.write("zero header block\n")
    end
    -- Every block gets at least one chunk, which may be empty.
    local latest = new(nil, nil) -- current chunk
    local sub_blocks = {}
    -- There is always a header at [1], though it may be nil
    -- If there are other Nodes, they are Blocks and must be appended.
    for i = 2, #block do
        sub_blocks[#sub_blocks + 1] = block[i]
        block[i] = nil
    end
    block[2] = latest
    -- State machine for chunking a block
    local back_blanks = 0
    -- first set of blank lines in a block belong to the first chunk
    local lead_blanks = true
    for i = 1, #block.lines do
        local v = block.lines[i]
        if v == "" then 
            -- increment back blanks for clinging subsequent lines
            back_blanks = back_blanks + 1
            -- for now, blanks attach to the preceding chunk
            latest.lines[#latest.lines + 1] = v
        else
            if back_blanks > 0 and lead_blanks == false then
                -- new chunk
                latest = new(nil, v)
                block[#block + 1] = latest
                back_blanks = 0
            else
                lead_blanks = false
                -- here we apply the cling rule to taglines
                -- local structure, id = structureOrProse(v)
                back_blanks = 0
                latest.lines[#latest.lines + 1] = v
            end
        end
    end
    -- Append blocks, if any, which follow our chunks
    for _, v in ipairs(sub_blocks) do
        block[#block + 1] = v
    end
    return block
end

c["__call"] = new
c["__index"] = c

return setmetatable({}, c)









