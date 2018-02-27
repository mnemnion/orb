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
--
--

local Node = require "peg/node"

-- Metatable for Docs.
--
local D = setmetatable({}, { __index = Node })

D.__tostring = function (doc)
    local phrase = ""
    for _,v in ipairs(doc) do
        phrase = phrase .. tostring(v) .. "\n"
    end

    return phrase .. "asdfs"
end

D.__index = D

-- Doc constructor.
--
local d = {}


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
function D.addBlock(doc, block)
    if not doc.latest then
        doc[1] = block 
    else
        local atLevel = doc.latest.level 
        if atLevel < block.level then
            -- add the block under the latest block
            doc.latest:addBlock(block)
        else
            doc[#doc + 1] = block
        end
    end
    doc.latest = block
    return doc
end

function D.addLine(doc, line)
    if doc.latest then
        doc.latest:addLine(line)
    else
        doc.lines[#doc.lines + 1] = line
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
    -- for now lets set root to 'false'
    doc.root = false
    return doc
end

setmetatable(D, Node)

d["__call"] = new

return setmetatable({}, d)
