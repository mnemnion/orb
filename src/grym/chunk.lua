-- * Chunk module
--
--   A Chunk is the container for the next level of granularity below
-- a Block. A given Block has a Header and zero or more Chunks.
--
-- A paragraph of prose is the simplest chunk. A list with a tag line is
-- a chunk also, as is a table. Most importantly for our short path, 
-- code blocks are chunks also.
--
-- Chunking needs to identify when it has structure, and when prose, on a 
-- line-by-line basis. It must also apply the cling rule to make sure that
-- e.g. tags are part of the chunk indicated by whitespacing. 
-- 
-- Chunking need not, and mostly should not, parse within structure or prose.
-- These categories are determined by the beginning of a line, making this
-- tractable. 






local Node = require "peg/node"

-- Metatable for Headers

local C = setmetatable({}, { __index = Node })
C.__index = C

C.__tostring = function(header) 
    return "Lvl " .. tostring(header.level) .. " ^: " 
           .. tostring(header.line)
end


-- Constructor/module

local c = {}


c["__call"] = new

return setmetatable({}, c)