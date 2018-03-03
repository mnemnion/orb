-- * Structure Module
--
--   Structure is our holding block for anything which is neither
-- prose nor code.  This includes taglines, lists, tables, and some
-- more advanced forms such as drawers.
--
-- For now we need them as containers for taglines, which are part of the short
-- path for knitting source code.
--
-- Note that structures do not have a =.lines= field.

local Node = require "peg/node"

local Hashline = require "grym/hashline"

-- ** Metatable for Structures

local S = setmetatable({}, Node)
S.__index = S

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
    if line_id == "hashline" then
        structure[1] = Hashline(line)
    end
    return structure
end

s.__call = new
s.__index = s

return setmetatable({}, s)
