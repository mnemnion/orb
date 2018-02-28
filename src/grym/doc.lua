-- * Doc module
--
-- Represents a Document, which is generally the same as a file, at first.
--
-- A document contains an array of blocks. 
--
-- At some point documents can also contain documents, this is not
-- currently supported.
--
--
-- ** Fields
--
--
-- In addition to the standard Node fields, a doc has:
-- 
-- - latest: The current block.  This will be in `doc[#doc]` but may
--           be several layers deep.
-- - lastOf: An array containing references to the last block of a
--           given level.
--

local Node = require "peg/node"
local Block = require "grym/block"

-- Metatable for Docs.
--
local D = setmetatable({}, { __index = Node })

D.__tostring = function (doc)
    local phrase = ""
    for _,v in ipairs(doc) do
        local repr = tostring(v)
        if repr ~= "" and repr ~= "\n" then
            phrase = phrase .. repr .. "\n"
        end
    end

    return phrase 
end

D.__index = D

-- Doc constructor.
--
local d = {}


function D.parentOf(doc, level)
    local i = level - 1
    local parent = nil
    while i > 0 do
        parent = doc.lastOf[i]
        if parent then
            return parent
        else
            i = i - 1
        end
    end

    return doc
end

-- Adds a block to a document.
--
-- This function looks at document level and places the block
-- accordingly.
-- 
-- - doc : the document
-- - block : block to be appended
--
-- returns: the document
--
function D.addBlock(doc, block, linum)
    if not doc.latest then
        doc[1] = block 
    else
        doc.latest.line_last = linum
        local atLevel = doc.latest.level 
        if atLevel < block.level then
            -- add the block under the latest block
            doc.latest:addBlock(block, linum)
        else
            -- append to parent of latest block
            doc:parentOf(block.level):addBlock(block, linum)
        end
    end
    doc.latest = block
    doc.lastOf[block.level] = block
    return doc
end

function D.addLine(doc, line, linum)
    if doc.latest then
        doc.latest:addLine(line)
    else
        -- a virtual zero block
        doc[1] = Block(0, linum)
        doc.latest = doc[1]
        doc.latest:addLine(line)
    end

    return doc
end


-- Creates a Doc Node.
--
-- @Doc: this is d
-- @str: the string representing the doc
--
-- @return: a Doc representing this data. 
--
local function new(Doc, str)
    local doc = setmetatable({}, D)
    doc.str = str
    doc.id = "doc"
    doc.latest = nil
    doc.lines = {}
    doc.lastOf = {}
    -- for now lets set root to 'false'
    doc.root = false
    return doc
end

setmetatable(D, Node)

d["__call"] = new

return setmetatable({}, d)
