
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

local function cat_lines(phrase, lines)
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

    return phrase, blanks
end

-- inverts a source code file into a grimoire document
function invert(str)
    local code_block = false
    local phrase = ""
    local lines = {}
    for _, line in ipairs(epeg.split(str, "\n")) do
        -- Two kinds of line: comment and code. For comment:
        if (L.match(L.P"-- ", line) 
            or (L.match(L.P("--"), line) and #line == 2)) then
            if code_block then
                phrase, lines = cat_lines(phrase, lines)
                phrase = cat_lines(phrase,write_footer())
                code_block = false
            end 
            lines[#lines + 1] = line:sub(4,  -1)
        else
            -- For code:
            if not code_block then
                phrase, lines = cat_lines(phrase, lines)
                phrase = cat_lines(phrase, write_header())
            end
            code_block = true
            lines[#lines + 1] = line
        end
    end
    -- Close any final code block
    if code_block then
        phrase = cat_lines(phrase, lines)
        phrase = cat_lines(phrase, write_footer())
    end
    return phrase
end

return invert