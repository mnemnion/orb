
local L = require "lpeg"

local epeg = require "peg/epeg"

local m = require "grym/morphemes"

local function isBlank(line)
    local all_blanks = L.match((m.__TAB__ + m._)^0, line)
    return (all_blanks == (#line + 1) or line == "")
end


-- We'll turn this into a proper constructor by and by
local inverter = {}

inverter.lang = "lua"
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

local function cat_lines(phrase, lines, return_foot)
    if type(lines) == "string" then
        return phrase .. lines .. "\n"
    end
    local blanks = {}
    for i ,l in ipairs(lines) do
        if isBlank(l) then
            blanks[#blanks + 1] = ""
        else
            if i < #lines and #blanks > 1 then
            -- for loop for blank clearing
                for _, bl in ipairs(blanks) do
                    phrase = phrase .. bl .. "\n"
                end
                blanks = {}
            end 
            phrase = phrase .. l .. "\n"
        end
    end

    local last_line_blank = #blanks > 1
    if return_foot then
        return phrase, blanks, last_line_blank
    else 
        for _, bl in ipairs(blanks) do
            phrase = phrase .. bl .. "\n"
        end
        return phrase, {}, last_line_blank
    end
end

-- *** matchLineType
--
--   Matches a line by type (comment, code, or blank) and either
-- concatenates to an existing block of this type or starts a new
-- one if the latest is different.
--
-- - #return : the latest block, which may be created here.
--
function matchLineType(latest, line)
    local function tagLatest(late, id)
        if not latest.id then
            latest.id = id
        end
        return latest
    end
    if not latest then latest = {} end
    if (L.match(L.P"-- ", line) 
            or (L.match(L.P("--"), line) and #line == 2)) then
        -- prose
        if not latest.id or latest.id ~= "prose" then
            -- new code block
            latest = { id = "prose"}
            latest[#latest + 1] = line
        else
            latest[#latest + 1] = line
        end
    elseif isBlank(line) then
        -- blank line
        if not latest.id or latest.id ~= "blank" then
            latest = { id = "blank"}
            latest[#latest + 1] = line
        else
            latest[#latest + 1] = line
        end
    else
        -- code line
        if not latest.id or latest.id ~= "prose" then
            -- new code block
            latest = { id = "prose" }
            latest[#latest + 1] = line
        else
            latest[#latest + 1] = line
        end
    end
    return latest
end

-- let's try this again
function invert(str)
    local blocks = {}
    local linum = 0
    local latest = nil
    for _, line in ipairs(epeg.split(str, "\n")) do
        linum = linum + 1
        -- each line is either comment, blank or code.
        local this_block = matchLineType(latest, line)
        if this_block ~= latest then
            blocks[#blocks + 1] = this_block
            latest = this_block
        end
    end
    local new_linum = 0
    for _, v in ipairs(blocks) do
        io.write("-->  " .. v.id .. "\n")
        for __, line in ipairs(v) do
            io.write(line .. "\n")
        end
    end
    -- turn the blocks into a phrase and return

    return ""
end

-- inverts a source code file into a grimoire document
function __invert(str)
    local code_block = false
    local phrase = ""
    local lines = {}
    local linum = 0
    local added_lines = 0
    for _, line in ipairs(epeg.split(str, "\n")) do
        line = inverter:filter(line)
        linum = linum + 1
        -- Two kinds of line: comment and code. For comment:
        if (L.match(L.P"-- ", line) 
            or (L.match(L.P("--"), line) and #line == 2)) then
            if code_block then
                phrase, lines = cat_lines(phrase, lines, true)
                phrase = cat_lines(phrase,inverter:write_footer())
                added_lines = added_lines + 1
                code_block = false
            end 
            lines[#lines + 1] = line:sub(4,  -1)
        else
            -- For code:
            if not code_block then
                local last_line_blank = nil
                phrase, lines, last_line_blank = cat_lines(phrase, lines)
                if not last_line_blank then 
                    phrase = phrase .. "\n"
                    added_lines = added_lines + 1 
                end
                phrase = cat_lines(phrase, inverter:write_header())
                added_lines = added_lines + 1
                code_block = true
            end
            lines[#lines + 1] = line
        end
    end
    -- Close any final code block
    if code_block then
        phrase, lines = cat_lines(phrase, lines, true)
        phrase = cat_lines(phrase, inverter:write_footer())
        added_lines = added_lines + 1
        phrase = cat_lines(phrase, lines)
    end
    -- DEV: Split the phrase to count lines
    local new_linum = 0
    for _, line in ipairs(epeg.split(phrase, "\n")) do
        new_linum = new_linum + 1
    end
    io.write("# lines: " .. linum .. "  New # lines: " 
        .. new_linum .. " - Added lines: " .. added_lines 
        .. " = " .. (new_linum - linum - added_lines) .. "\n")
    return phrase
end

return invert