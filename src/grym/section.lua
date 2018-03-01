-- * Section metatable
--
-- sections consist of a header and body.
--
-- In the first pass, we fill a lines array with the raw
-- contents of the section. 
--
-- This is subsequently refined into various structures and
-- chunks of prose. 
--
--
-- ** Array
--
--
-- The array portion of a section starts at [1] with a Header. The
-- rest consists, optionally, of Nodes of types Chunk and section.
--
--
-- ** Fields
--
-- - header : The header for the section.
-- - level : The header level, lifted from the header for ease of use
-- - lines : An array of the lines owned by the section. Note that 
--           this doesn't include the header. 

local Node = require "peg/node"

local Header = require "grym/header"

-- Metatable for sections

local S = setmetatable({}, { __index = Node})
S.__index = S

function S.__tostring(section)
    local phrase = ""
    for _,v in ipairs(section) do
        local repr = tostring(v)
        if (repr ~= "" and repr ~= "\n") then
            io.write("repr: " .. repr .. "\n")
            phrase = phrase .. repr .. "\n"
        else
            io.write("newline filtered\n")
        end
    end

    return phrase
end


function S.dotLabel(section)
    return "section: " .. tostring(section.line_first) 
        .. "-" .. tostring(section.line_last)
end



function S.check(section)
    for _,v in ipairs(section) do
        if (_ == 1) then
            if section.header then
                assert(v.id == "header")
            end
        else
            assert(v.id == "section" or v.id == "chunk")
        end
    end
    assert(section.level)
    assert(section.id)
    assert(section.lines)
    assert(section.line_first)
    assert(section.line_last)
end

-- Add a line to a section. 
-- 
-- - section: the section
-- - line: the line
--
-- return : no
--
function S.addLine(section, line)
    section.lines[#section.lines + 1] = line
    return section
end


function S.addSection(section, newsection, linum)
    if linum > 0 then
        section.line_last = linum - 1
    end
    section[#section + 1] = newsection
    return section
end


-- Constructor/module

local s = {}

-- Creates a section Node

local function new(section, header, linum)
    local section = setmetatable({}, S)
    if type(header) == "number" then
        -- We have a virtual header
        section[1] = Header("", header)
        section.header = nil
        section.level = header
    else
        section[1] = header
        section.header = header
        section.level = header.level
    end
    section.line_first = linum
    section.lines = {}
    section.id = "section"
    return section
end

s["__call"] = new

return setmetatable({}, s)