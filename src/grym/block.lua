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
--
-- ** Array
--
--
-- The array portion of a block starts at [1] with a Header. The
-- rest consists, optionally, of Nodes of types Chunk and Block.
--
--
-- ** Fields
--
-- - header : The header for the block.
-- - level : The header level, lifted from the header for ease of use
-- - lines : An array of the lines owned by the block. Note that 
--           this doesn't include the header. 

local Node = require "peg/node"

-- Metatable for blocks

local B = setmetatable({}, { __index = Node})
B.__index = B


function B.check(block)
    for _,v in ipairs(block) do
        if (_ == 1) then
            assert(v.id == "header" or v.id == "block" or v.id == "chunk")
        else
            assert(v.id == "block" or v.id == "chunk")
        end
    end
    assert(block.header)
    assert(block.level)
    assert(block.id)
    assert(block.lines)
    assert(block.parent)
end

-- Add a line to a block. 
-- 
-- - block: the block
-- - line: the line
--
-- return : no
--
function B.addLine(block, line)
    block.lines[#block.lines + 1] = line
    return block
end


function B.addBlock(block, newBlock)
    block[#block + 1] = newBlock
    return block
end

-- Constructor/module

local b = {}

-- Creates a Block Node

local function new(Block, header, parent)
    local block = setmetatable({}, B)
    block[1] = header
    block.header = header
    block.level = header.level
    block.lines = {}
    block.parent = function() return parent end
    block.id = "block"
    block:check()
    return block
end

b["__call"] = new

return setmetatable({}, b)