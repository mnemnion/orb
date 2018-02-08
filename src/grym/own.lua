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

local epeg = require "peg/epeg"

local Csp = epeg.Csp

local a = require "../lib/ansi"

local ast = require "peg/ast"

local Node = require "peg/node"

local m = require "grym/morphemes"

local own = {}

own.__error = true



local blue = tostring(a.blue)
local red = tostring(a.red)
local dim = tostring(a.dim)
local green = tostring(a.green)
local cl   = tostring(a.clear)

-- *** Helper functions for own.parse

-- matches a header line.
-- returns a boolean isHeader and a left-unpadded header line
local function match_head(str) 
    if str ~= "" and L.match(m.header, str) then
        local trimmed = str:sub(L.match(m.WS, str))
        return true, L.match(m.tars, trimmed) - 1
    else 
        return false, 0
    end
end

-- Trims leading whitespace, returning the amount taken and
-- the trimmed string.
-- 
local function lead_whitespace(str)
    local lead_ws = L.match(m.WS, str)
    if lead_ws > 1 then
        io.write(green..("%"):rep(lead_ws - 1)..cl)
        return lead_ws, str:sub(lead_ws)
    else
        return 0, str
    end
end

local function nodulate(str, id, root)
    local node = epeg.spanner(1, #str, str, root)
    node.id = id
    return setmetatable(node, Node)
end

-- Takes a string, parsing ownership.
-- Returns a Forest with some enhancements.
--
function own.parse(str)
    local ER = own.__error
    local doc
    doc = nodulate(str, "doc", doc)
    local linum = 1
    io.write("Num lines -> "..tostring(#(epeg.split(str,"\n"))).."\n")
    for _, line in ipairs(epeg.split(str, "\n")) do
        linum = linum + 1
        local l, err = line:gsub("\t", "  "):gsub("\r", "") -- tab and return filtration
        if err ~= 0 and ER then
            io.write("\n"..dim..red..err.." TABS DETECTED WITHIN SYSTEM\n"..cl)
        end

        -- We should always have a string but..
        if l then
            local indent, l_trim = lead_whitespace(l)
            local isHeader, levels = match_head(l) 

            if isHeader then
                io.write(blue..l_trim..cl.."\n")
                doc[#doc + 1] = nodulate(l_trim, "header", doc)
            else 
                io.write(l_trim.."\n")
            end
        elseif ER then
            io.write("HUH?")
        end
    end
    io.write(tostring(doc))
end

return own