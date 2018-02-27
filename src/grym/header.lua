-- * Header metatable
--
-- A specialized type of Node, used for first-pass ownership and 
-- all subsequent operations. 


local Node = require "peg/node"


-- A header contains a header line, that is, one which begins with `WS^0 * '*'^1 * ' '`.
--
-- In addition to the standard Node fields, a header has:
-- 
--  - `parent()`, a function that returns its parent, which is either a **block** or a **doc**.
--  - `dent`, the level of indentation of the header. Must be non-negative. 
--  - `level`, the level of ownership (number of tars).
--  - `line`, the rest of the line (stripped of lead whitespace and tars)


-- Metatable for Headers

local H = setmetatable({}, { __index = Node })
H.__index = H

H.__tostring = function(header) 
    return "Lvl " .. tostring(header.level) .. " ^: " 
           .. tostring(header.line)
end


-- Constructor/module

local h = {}


-- Creates a Header Node.
--
-- @Header: this is h
-- @line: string containing the left-stripped header line (no tars or whitespace).
-- @level: number representing the document level of the header
-- @spanner: a table containing the Node values
-- @parent: a closure which returns the containing Node. Must be "doc" or "block".
--
-- @return: a Header representing this data. 


local function new(Header, line, level, first, last, parent)
    local header = setmetatable({}, H)
    header.line = line
    header.level = level
    header.first = first
    header.last = last
    header.parent = function() return parent end
    header.id = "header"
    -- for now lets set root to 'false'
    -- nodes classically return root but unclear that I actually use
    header.root = false
    return header
end

function H.howdy() 
    io.write("Why hello!\n")
end


h["__call"] = new

return setmetatable({}, h)
