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




local Node = require "peg/node"

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


-- Chunks a Block
-- 
-- block: the block
--
-- returns: the same block, filled in with chunks

function c.chunk(block)
    for _,v in ipairs(block.lines) do
        --io.write(v.."\n")
    end
    return {}
end

c["__call"] = new
c["__index"] = c

return setmetatable({}, c)









