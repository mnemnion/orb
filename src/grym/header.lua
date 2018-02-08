-- * Header metatable
--
-- A specialized type of Node, used for first-pass ownership and 
-- all subsequent operations. 

local Node = require "peg/node"


-- A header contains an array of either blocks or headers.
--
-- In addition to the standard Node fields, a header has:
-- 
--  - `parent()`, a function that returns its parent, which is either a **header** or a **doc**.
--  - `dent`, the level of indentation of the header. Must be non-negative.
--  - `level`, the level of ownership (number of tars).
--  - `line`, the rest of the line (stripped of lead whitespace and tars)

-- Metatable for Headers
local H = setmetatable({}, { __index = Node})

-- function-like table
local h = {}

H.__tostring = function(header) 
    return "^: "  .. tostring(header.first) ..
           " $: " .. tostring(header.last)  .. " " 
end

-- Creates a Header Node.
--
-- @Header: this is h
-- @line: the left-stripped header line, a string
-- @level: number representing the document level of the header
-- @spanner: a table containing the Node values
-- @parent: a closure which returns the containing Node. Must be "doc" or "header".
--
-- @return: a Header representing this data. 
-- - [ ] TODO validate parent.id
--
local function new(Header, line, level, first, last, parent)
    local header = setmetatable({}, H)
    header.line = line
    header.level = level
    header.first = first
    header.last = last
    header.parent = function() return parent end
    header.id = "header"
    -- for now lets set root to 'false'
    header.root = false
    return header
end

setmetatable(H, Node)

h["__call"] = new

return setmetatable({}, h)
