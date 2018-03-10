local L = require "lpeg"

local Node = require "peg/node"

local m = require "grym/morphemes"

local H = setmetatable({}, { __index = Node })
H.__index = H

H.__tostring = function(header) 
    return "Lvl " .. tostring(header.level) .. " ^: " 
           .. tostring(header.line)
end

function H.dotLabel(header)
    return header.line
end

function H.toMarkdown(header)
    return ("#"):rep(header.level) .. " " .. header.line
end

local h = {}

function h.match(str) 
    if str ~= "" and L.match(m.header, str) then
        local trimmed = str:sub(L.match(m.WS, str))
        local level = L.match(m.tars, trimmed) - 1
        local bareline = trimmed:sub(L.match(m.tars * m.WS, trimmed))
        return true, level, bareline
    else 
        return false, 0, ""
    end
end

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


h.__call = new
h.__index = h

return setmetatable({}, h)

