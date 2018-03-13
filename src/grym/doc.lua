





















local u = require "lib/util"

local Node = require "peg/node"
local Block = require "grym/section"
local own = require "grym/own"






local D = setmetatable({}, { __index = Node })

D.__tostring = function (doc)
    local phrase = ""
    for _,v in ipairs(doc) do
        local repr = tostring(v)
        if repr ~= "" and repr ~= "\n" then
            phrase = phrase .. repr .. "\n"
        end
    end

    return phrase 
end

D.__index = D

D.own = own

function D.dotLabel(doc)
    return "doc - " .. tostring(doc.linum)
end 

function D.toMarkdown(doc)
    local phrase = ""
    for _, node in ipairs(doc) do
        if node.toMarkdown then
            phrase = phrase .. node:toMarkdown()
        else 
            u.freeze("no toMarkdown method for " .. node.id)
        end
    end
    return phrase
end






local d = {}


function D.parentOf(doc, level)
    local i = level - 1
    local parent = nil
    while i > 0 do
        parent = doc.lastOf[i]
        if parent then
            return parent
        else
            i = i - 1
        end
    end

    return doc
end














function D.addSection(doc, block, linum)
    if not doc.latest then
        doc[1] = block 
    else
        if linum > 0 then
            doc.latest.line_last = linum - 1
        end
        local atLevel = doc.latest.level 
        if atLevel <= block.level then
            -- add the block under the latest block
            doc.latest:addSection(block, linum)
        else
            local parentis = doc:parentOf(block.level)
            if parentis.id == "doc" then
                doc.latest:addSection(block, linum)
            else
                parentis:addSection(block, -1)
            end
        end
    end
    doc.latest = block
    doc.lastOf[block.level] = block
    return doc
end

function D.addLine(doc, line, linum)
    if doc.latest then
        doc.latest:addLine(line)
    else
        -- a virtual zero block
        doc[1] = Block(0, linum)
        doc.latest = doc[1]
        doc.latest:addLine(line)
    end

    return doc
end












local function new(Doc, str)
    local doc = setmetatable({}, D)
    doc.str = str
    doc.id = "doc"
    doc.latest = nil
    doc.lines = {}
    doc.lastOf = {}
    -- for now lets set root to 'false'
    doc.root = false
    return doc:own(str)
end

setmetatable(D, Node)

d["__call"] = new

return setmetatable({}, d)
