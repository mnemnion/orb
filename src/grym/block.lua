

































local L = require "lpeg"

local Node = require "peg/node"
local Codeblock = require "grym/codeblock"
local Structure = require "grym/structure"

local m = require "grym/morphemes"
local util = require "../lib/util"
local freeze = util.freeze





local B = setmetatable({}, { __index = Node })
B.__index = B

B.__tostring = function(block) 
    return "Block"
end

function B.addLine(block, line)
    if L.match(m.tagline_sys_p, line) then
        block[#block + 1] = Structure(line, "hashline")
    elseif L.match(m.tagline_user_p, line) then
        block[#block + 1] = Structure(line, "handleline")
        -- Eventually Blocks won't have lines, meantime:
    else
        block.lines[#block.lines + 1] = line
    end

    return block
end







function B.toValue(block)
    block.val = ""
    for _,v in ipairs(block.lines) do
        block.val = block.val .. v .. "\n"
    end

    return block.val
end

function B.toMarkdown(block)
    if block[1] and block[1].id == "codeblock" then
        return block[1]:toMarkdown()
    end
    
    return block:toValue()
end

function B.dotLabel(block)
    return "block " .. tostring(block.line_first) 
        .. "-" .. tostring(block.line_last)
end






local b = {}

local function new(Block, lines, linum)
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
