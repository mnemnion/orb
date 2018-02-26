-- * Doc module
--
-- Represents a Document, which is generally the same as a file, at first.
--
--
--
-- A document contains an array of either blocks or docs.
--
-- In addition to the standard Node fields, a doc has:
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
    -- for now lets set root to 'false'
    doc.root = false
    return doc
end

setmetatable(D, Node)

d["__call"] = new

return setmetatable({}, d)
