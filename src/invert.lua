
local L = require "lpeg"

local epeg = require "peg/epeg"

local m = require "grym/morphemes"

local u = require "../lib/util"

local ansi = require "../lib/ansi"

local green, blue = ansi.green, ansi.blue

local function isBlank(line)
    local all_blanks = L.match((m.__TAB__ + m._)^0, line)
    return (all_blanks == (#line + 1) or line == "")
end


-- We'll turn this into a proper constructor by and by
local inverter = {}

inverter.lang = "lua"
inverter.comment = L.P"--"
inverter.tab_to_space = "   "


function inverter.write_header(inverter)
    return "#!" .. inverter.lang .. "\n"
end

function inverter.write_footer(inverter)
    return "#/" .. inverter.lang .. "\n"
end

function inverter.filter(inverter, line)
    if isBlank(line) then
        return ""
    else 
        return line:gsub("\t", inverter.tab_to_space):gsub("\r", "")
    end
end

local function cat_lines() end --stub out

local function matchComment(line)
    return (L.match(inverter.comment * m._, line) 
            or (L.match(inverter.comment, line) and #line == 2))
end

-- *** matchLineType
--
--   Matches a line by type (comment, code, or blank) and either
-- concatenates to an existing block of this type or starts a new
-- one if the latest is different.
--
-- - #return : the latest block, which may be created here.
--
local function sortLine(latest, line)
    local block = latest or {}

    if matchComment(line) then
        -- prose
        if not block.id or block.id ~= "prose" then
            -- new code block
            block = { id = "prose"}
            block[#block + 1] = line
        else
            block[#block + 1] = line
        end
    elseif isBlank(line) then
        -- blank line
        if not block.id or block.id ~= "blank" then
            block = { id = "blank"}
            block[#block + 1] = line
        else
            block[#block + 1] = line
        end
    else
        -- code line
        if not block.id or block.id ~= "code" then
            -- new code block
            block = { id = "code" }
            block[#block + 1] = line
        else
            block[#block + 1] = line
        end
    end

    return block
end

local function catBlocks(blocks)
    local linum = 0
    local function toLines(block) 
        local phrase = ""
        for j = 1, #block do
            linum = linum + 1
            phrase = phrase .. block[j] .. "\n"
        end
        return phrase
    end
    local phrase = toLines(blocks[1]) 
    for i = 2, #blocks do
        if blocks[i].id == "code" then

            -- if preceding block is blank and before that is
            -- code, write blanks and code
            if blocks[i - 1].id == "blank" and 
                i > 2 and blocks[i - 2].id == "code" then
                phrase = phrase .. toLines(blocks[i - 1]) .. toLines(blocks[i])

            -- if preceding block is blank and before that is 
            -- prose or nothing, write blanks, header, and code
            elseif blocks[i - 1].id == "blank" and 
                (blocks[i - 2] == nil or blocks[i - 2].id == "prose") then
                phrase = phrase .. toLines(blocks[i - 1])
                                .. inverter:write_header()
                                .. toLines(blocks[i])

            -- if preceding block is prose, write a blank line, 
            -- header, and code. 
            elseif blocks[i - 1].id == "prose" then
                phrase = phrase .. "\n" .. inverter:write_header() 
                                .. toLines(blocks[i])
            else
                u.freeze("Reached a bad state on code in catLines")
            end
        elseif blocks[i].id == "prose" then

            -- if preceding block is blank and before that is
            -- code, write footer, blanks, and prose
            if blocks[i - 1].id == "blank" and 
                i > 2 and blocks[i - 2].id == "code" then
                phrase = phrase .. inverter:write_footer() 
                                .. toLines(blocks[i - 1]) .. toLines(blocks[i])
                                             
            -- if preceding block is code, write a footer, newline,
            -- and prose
            elseif (blocks[i - 1].id == "code") then
                phrase = phrase .. inverter:write_footer()
                                .. "\n" .. toLines(blocks[i])

            -- if preceding line is blank and before that is 
            -- nothing or more prose, write blanks, then prose.
            elseif blocks[i - 1].id == "blank" and 
                (blocks[i - 2] == nil or blocks[i - 2].id == "prose") then
                phrase = phrase .. toLines(blocks[i - 1]) .. toLines(blocks[i])

            else
                u.freeze("Reached a bad state on prose in catLines")
            end
        end 
        
    end
    if blocks[#blocks].id == "code" or
        (blocks[#blocks].id == "blank" 
            and blocks[#blocks - 1].id == "code") then
        phrase = phrase .. inverter:write_footer()
    end
    -- Note that there may be a final block of blank lines which we are
    -- happy to simply drop. 
    return phrase, linum
end

-- ** Grym:invert(str)
--
-- This takes a source file and inverts it into Grimoire format.
--
-- - str: The source file as a single string
--
-- - #return: The Grimoire document as a string
--
local function invert(str)
    local blocks = {}
    local linum = 0
    local latest = nil
    for _, line in ipairs(epeg.split(str, "\n")) do
        linum = linum + 1
        line = inverter:filter(line)
        -- each line is either comment, blank or code.
        local this_block = sortLine(latest, line)
        if this_block ~= latest then
            blocks[#blocks + 1] = this_block
            latest = this_block
        end
    end
    local new_linum = 0
    ---[[ This entire check should be wrapped in a utility assert
    for _, v in ipairs(blocks) do
        for __, line in ipairs(v) do
            new_linum = new_linum + 1
        end
    end
    --]]
    assert(linum == new_linum)

    local phrase, cat_linum = catBlocks(blocks)
    return phrase
end


return invert