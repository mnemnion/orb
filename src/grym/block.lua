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

function B.__tostring(block)
    local phrase = ""
    for _,v in ipairs(block) do
        local repr = tostring(v)
        if (repr ~= "" and repr ~= "\n") then
            io.write("repr: " .. repr .. "\n")
            phrase = phrase .. repr .. "\n"
        else
            io.write("newline filtered\n")
        end
    end

    return phrase
end



function B.check(block)
    for _,v in ipairs(block) do
        if (_ == 1) then
            if block.header then
                assert(v.id == "header")
            end
        else
            assert(v.id == "block" or v.id == "chunk")
        end
    end
    assert(block.level)
    assert(block.id)
    assert(block.lines)
    assert(block.line_first)
    assert(block.line_last)
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


function B.addBlock(block, newBlock, linum)
    block.line_last = linum
    block[#block + 1] = newBlock
    return block
end

-- Constructor/module

local b = {}

-- Creates a Block Node

local function new(Block, header, linum)
    local block = setmetatable({}, B)
    if type(header) == "number" then
        -- We have a virtual header
        block[1] = nil 
        block.header = nil
        block.level = header
    else
        block[1] = header
        block.header = header
        block.level = header.level
    end
    block.line_first = linum
    block.lines = {}
    block.id = "block"
    return block
end

b["__call"] = new

return setmetatable({}, b)