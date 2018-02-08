-- * Ownership module
--
--    Taking a multi-pass approach to this Grimoire instance will benefit us 
-- in a few ways. 
--
--    First, Grimoire itself is structured in a certain fashion. The 
-- straightforward thing is to mirror that fashion in code.
--
--    Second, the critical path right now is simple code generation from 
-- Grimoire documents. Parsing prose gets useful later, for now I simply
-- wish to unravel some existing code into Grimoire format and start working
-- on it accordingly. 

local L = require "lpeg"

local a = require "../lib/ansi"

local ast = require "peg/ast"

local F = require "peg/forest"

local m = require "grym/morphemes"

local own = {}

own.__error = true

local blue = tostring(a.blue)
local cl   = tostring(a.clear)

-- *** Helper functions for own.parse

local function match_head(str) 
    if str ~= "" and L.match(m.header, str) then
        local trimmed = str:sub(L.match(m.WS, str))
        return true, L.match(m.tars, trimmed) - 1
    end
end

-- Takes a string, returning a Forest with some enhancements.
function own.parse(str)
    local sections = setmetatable({}, F)
    for line in str:gmatch("[^\r\n]+") do
        local l, err = line:gsub("\t", "  ") -- tab filtration
        if err ~= 0 and own.__error then
            io.write(tostring(a.dim)..tostring(a.red)..tostring(err) 
                .. " TABS DETECTED WITHIN SYSTEM\n" .. tostring(a.clear))
        end

        -- try to match a header
        if l then
            local isHeader, levels = match_head(l) 
            if isHeader then
                io.write(blue..tostring(levels).." "..cl..l.."\n")
            end
        end
    end

end

return own