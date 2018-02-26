-- * Block metatable
--
-- Blocks consist of a header and body.
--
-- In the first pass, we fill a lines array with the raw
-- contents of the block. 
--
-- This is subsequently refined into various structures and
-- chunks of prose. 
--

local Node = require "peg/node"

-- Metatable for blocks

local B = setmetatable({}, { __index = Node})

-- Constructor/module

local b = {}

-- Creates a Block Node

local function new(Block, header, parent)
    local block = setmetatable({}, { __index = B })
    block.header = header
    block.parent = function() return parent end
    block.id = "block"
    return block
end

b["__call"] = new

return b