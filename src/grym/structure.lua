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
local u = require "../lib/util"

local Hashline = require "grym/hashline"
local Handleline = require "grym/handleline"

-- ** Metatable for Structures

local S, s = u.inherit(Node)

function S.dotLabel(structure)
    -- This is a shim and will break.
    if structure.temp_id then 
        return structure.temp_id
    else
        return "structure"
    end
end

-- ** Constructor module


local function new(Structure, line, line_id)
    local structure = setmetatable({}, S)
    structure.id = "structure"
    if line_id == "hashline" then
        structure[1] = Hashline(line)
    elseif line_id == "handleline" then
        structure[1] = Handleline(line)
    end
    
    return structure
end


return u.export(s, new)
