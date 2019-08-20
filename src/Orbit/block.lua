


































local L = require "lpeg"

local Node = require "espalier/node"
local Codeblock = require "Orbit/codeblock"
local Structure = require "Orbit/structure"
local Prose = require "Orbit/prose"

local s = require "singletons/status" ()

local m = require "Orbit/morphemes"






local B = setmetatable({}, { __index = Node })
B.__index = B

B.__tostring = function(block)
    return "Block"
end

function B.addLine(block, line)
    if L.match(m.tagline_hash_p, line) then
        block[#block + 1] = Structure(line, "hashline", block.str)
    elseif L.match(m.tagline_handle_p, line) then
        block[#block + 1] = Structure(line, "handleline", block.str)
        -- Eventually Blocks won't have lines, meantime:
    else
        block.lines[#block.lines + 1] = line
    end

    return block
end






function B.parseProse(block)
    if block[1] then
        if block[1].id == "codeblock" then
            return ""
        end
    else
        block[1] = Prose(block)
        block.lines = nil
        return block[1]
    end
end








function B.toString(block)
    local phrase = ""
    for _,v in ipairs(block.lines) do
        phrase = phrase .. v .. "\n"
    end
    return phrase
end

function B.toValue(block)
    block.val = block:toString()
    return block.val
end

function B.toMarkdown(block)
    if block[1] and (block[1].id == "codeblock"
      or block[1].id == "prose") then
        return block[1]:toMarkdown()
    else
        return block:toString()
    end
end

function B.dotLabel(block)
    return "block " .. tostring(block.line_first)
        .. "-" .. tostring(block.line_last)
end






local b = {}

local function new(Block, lines, linum, str)
    local block = setmetatable({}, B)
    block.lines = {}
    block.line_first = linum
    if (lines) then
        if type(lines) == "string" then
            block:addLine(lines)
        elseif type(lines) == "table" then
            for _, l in ipairs(lines) do
                block:addLine(l)
            end
        else
            freeze("Error: in block.new type of `lines` is " .. type(lines))
        end
    end

    block.id = "block"
    return block
end













local function structureOrProse(line)
    if L.match(m.tagline_p, line) then
        return true, "tagline"
    elseif L.match(m.listline_p, line) then
        return true, "listline"
    elseif L.match(m.tableline_p, line) then
        return true, "tableline"
    end
    return false, ""
end

b["__call"] = new
b["__index"] = b

return setmetatable({}, b)
