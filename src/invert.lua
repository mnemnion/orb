
local L = require "lpeg"

local epeg = require "peg/epeg"

local m = require "grym/morphemes"

local function write_header()
    return "#!lua\n"
end

local function write_footer()
    return "#/lua\n"
end

local function isBlank(line)
    local all_blanks = L.match((m.__TAB__ + m._)^0, line)
    return (all_blanks == #line or line == "")
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

-- inverts a source code file into a grimoire document
function invert(str)
    local code_block = false
    local phrase = ""
    local lines = {}
    local linum = 1
    local added_lines = 0
    for _, line in ipairs(epeg.split(str, "\n")) do
        -- Two kinds of line: comment and code. For comment:
        if (L.match(L.P"-- ", line) 
            or (L.match(L.P("--"), line) and #line == 2)) then
            if code_block then
                phrase, lines = cat_lines(phrase, lines, true)
                phrase = cat_lines(phrase,write_footer())
                added_lines = added_lines + 1
                code_block = false
            end 
            lines[#lines + 1] = line:sub(4,  -1)
        else
            -- For code:
            if not code_block then
                local last_line_blank = nil
                phrase, lines, last_line_blank = cat_lines(phrase, lines)
                if not last_line_blank then phrase = phrase .. "\n" end
                phrase = cat_lines(phrase, write_header())
                added_lines = added_lines + 1
            end
            code_block = true
            lines[#lines + 1] = line
        end
        linum = linum + 1
    end
    -- Close any final code block
    if code_block then
        phrase, lines = cat_lines(phrase, lines, true)
        phrase = cat_lines(phrase, write_footer())
        added_lines = added_lines + 1
        phrase = cat_lines(phrase, lines)
    end
    -- DEV: Split the phrase to count lines
    local new_linum = 1
    for _, line in ipairs(epeg.split(phrase, "\n")) do
        new_linum = new_linum + 1
    end
    io.write("# lines: " .. linum .. "  New # lines: " 
        .. new_linum .. " - Added lines: " .. added_lines 
        .. " = " .. (new_linum - linum - added_lines) .. "\n")
    return phrase
end

return invert