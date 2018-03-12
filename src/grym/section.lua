local L = require "lpeg"

local u = require "lib/util"

local Node = require "peg/node"

local Header = require "grym/header"
local Block = require "grym/block"
local Codeblock = require "grym/codeblock"
local m = require "grym/morphemes"

local S, s = u.inherit(Node)

function S.__tostring(section)
    local phrase = ""
    for _,v in ipairs(section) do
        local repr = tostring(v)
        if (repr ~= "" and repr ~= "\n") then
            io.write("repr: " .. repr .. "\n")
            phrase = phrase .. repr .. "\n"
        end
    end

    return phrase
end

function S.dotLabel(section)
    return "section: " .. tostring(section.line_first) 
        .. "-" .. tostring(section.line_last)
end

function S.toMarkdown(section)
    local phrase = ""
    for _, block in ipairs(section) do
        if block.toMarkdown then
            phrase = phrase .. block:toMarkdown()
        else 
            u.freeze("no toMarkdown method in " .. block.id)
        end
    end

    return phrase
end

function S.check(section)
    for i, v in ipairs(section) do
        if (i == 1) then
            if section.header then
                assert(v.id == "header")
            end
        else
            assert(v.id == "section" or v.id == "block")
        end
    end
    assert(section.level)
    assert(section.id)
    assert(section.lines)
    assert(section.line_first)
    assert(section.line_last)
end

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

local function isTagline(line)
    return L.match(m.tagline_p, line)
end

local function fwdBlanks(lines, linum)
    local fwd = 0
    local index = linum + 1
    if index > #lines then 
        return 0
    else 
        for i = index, #lines do
            if lines[i] == "" then
                fwd = fwd + 1
            else
                break
            end
        end
    end
    return fwd
end

function S.block(section)
    -- There is always a header at [1], though it may be nil
    -- If there are other Nodes, they are sections and must be appended
    -- after the blocks.
    local sub_sections = {}
    for i = 2, #section do
        sub_sections[#sub_sections + 1] = section[i]
        section[i] = nil
    end

    -- Every section gets at least one block, at [2], which may be empty.
    local latest = Block(nil, section.line_first) -- current block
    section[2] = latest

    -- State machine for blocking a section
    local back_blanks = 0
    -- first set of blank lines in a section belong to the first block
    local lead_blanks = true
    -- Track code blocks in own logic
    local code_block = false
    -- Tags also
    local tagging = false
    for i = 1, #section.lines do
        local inset = i + section.line_first
        local l = section.lines[i]
        if not code_block then
            if l == "" then 
                -- increment back blanks for clinging subsequent lines
                back_blanks = back_blanks + 1
                -- blank lines attach to the preceding block
                latest:addLine(l)
            else
                local isCodeHeader, level, l_trim = Codeblock.matchHead(l)
                if isCodeHeader then
                    code_block = true
                    if not tagging then
                        -- create a new block for the codeblock
                        latest.line_last = inset - 1
                        latest = Block(nil, inset)
                        latest[1] = Codeblock(level, l_trim, inset)
                        section[#section + 1] = latest
                    else
                        -- preserve existing block and add codeblock
                        tagging = false
                        latest[1] = Codeblock(level, l_trim, inset)
                    end
                elseif isTagline(l) then
                    tagging = true
                    -- apply cling rule
                    local fwd_blanks = fwdBlanks(section.lines, i)
                    if fwd_blanks > back_blanks then
                        latest:addLine(l)
                    else
                        -- new block
                        latest.line_last = inset - 1
                        latest = Block(l, inset)
                        section[#section + 1] = latest
                        back_blanks = 0
                    end                        
                else
                    if back_blanks > 0 and lead_blanks == false then
                        if not tagging then
                        -- new block
                            latest.line_last = inset - 1
                            latest = Block(l, inset)
                            section[#section + 1] = latest
                            back_blanks = 0
                        else
                            latest:addLine(l)
                            tagging = false
                        end 
                    else
                        -- continuing a block
                        lead_blanks = false
                        back_blanks = 0
                        latest:addLine(l)
                    end
                end
            end
        else
            -- Collecting a code block
            local isCodeFoot, level, l_trim = Codeblock.matchFoot(l)
            if (isCodeFoot and level == latest[1].level) then
                code_block = false
                latest[1].footer = l_trim
                latest[1].line_last = inset
            else
                latest[1].lines[#latest[1].lines + 1] = l
            end
            -- Continue in normal parse mode
            -- This may add more lines to the code block
        end
    end
    -- Auto-close a code block with no footer.
    if latest[1] and latest[1].id == "codeblock" and not latest[1].line_last then
        latest[1].line_last = #section.lines
    end

    -- Append sections, if any, which follow our blocks
    for _, v in ipairs(sub_sections) do
        section[#section + 1] = v
    end
    return section
end

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

return u.export(s, new)

