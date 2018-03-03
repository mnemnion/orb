-- * Structure Module
--
--   Structure is our holding block for anything which is neither
-- prose nor code.  This includes taglines, lists, tables, and some
-- more advanced forms such as drawers.
--
-- For now we need them as containers for taglines, which are part of the short
-- path for knitting source code.

local Node = require "peg/node"


-- ** Metatable for Structures

local S = setmetatable({}, Node)
S.__index = S

function S.addLine(structure, line, line_id)
    structure.lines[#structure.lines + 1] = line
    structure.temp_id = line_id
    return structure
end

function S.dotLabel(structure)
    -- This is a shim and will break.
    if structure.temp_id then 
        return structure.temp_id
    else
        return "structure"
    end
end



-- ** Constructor module

local s = {}


local function new(Structure, line, line_id)
    local structure = setmetatable({}, S)
    structure.id = "structure"
    structure.lines = {}
    structure:addLine(line, line_id)

    return structure
end

s.__call = new
s.__index = s

return setmetatable({}, s)
