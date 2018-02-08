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

local H = {}

local h = {}

-- Creates a Header Node.
-- @line: the left-stripped header line, a string
-- @level: number representing the document level of the header
-- @spanner: a table containing the Node values
-- @parent: a reference to the containing Node. Must be "doc" or "header".
--
-- @return: a Header representing this data. 
local function new(Header, line, level, spanner, parent)
    local header = setmetatable({}, Node)
    header.line = line
    header.level = level
    header.first = spanner.first
    header.last = spanner.last
    header.id = "header"
    -- for now lets set root to 'false'
    header.root = false
    return header
end

setmetatable(H, Node)

H["__call"] = new

setmetatable(h, H)

h.new = new

return h
