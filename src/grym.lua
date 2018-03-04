-- Grimoire, a metalanguage for magic spells

require "pl.strict"

local verbose = false


local pl_file = require "pl.file"
local pl_dir = require "pl.dir"
local getfiles = pl_dir.getfiles
local read = pl_file.read
local write = pl_file.write

local L = require "lpeg"


local ast = require "peg/ast"
local epeg = require "peg/epeg"

local P_grym = require "grym/grymmyr" 

local grym = {}

local function parse(str) 
    return ast.parse(P_grym, str)
end

samples = getfiles("samples")

local own = require "grym/own"

local function write_header()
    return "#!lua\n"
end

local function write_footer()
    return "#/lua\n"
end

local function cat_lines(phrase, lines)
    if type(lines) == "string" then
        return phrase .. lines .. "\n"
    end

    for i = 1, #lines do
        phrase = phrase .. lines[i] .. "\n"
    end

    return phrase
end

-- inverts a source code file into a grimoire document
function grym.invert(str)
    local code_block = false
    local phrase = ""
    local lines = {}
    for _, line in ipairs(epeg.split(str, "\n")) do
        -- Two kinds of line: comment and code. For comment:
        if (L.match(L.P"-- ", line) 
            or (L.match(L.P("--"), line) and #line == 2)) then
            if code_block then
                phrase = cat_lines(phrase, lines)
                phrase = cat_lines(phrase,write_footer())
                code_block = false
                lines = {}
            end 
            phrase = phrase .. line:sub(4,  -1) .. "\n"
        else
            -- For code:
            if not code_block then
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



-- Run the samples and make dotfiles
for _,v in ipairs(samples) do
    if v:match("~") == nil then
        if verbose then io.write(v) end
        local sample = read(v)
        io.write(v.."\n")
        local doc = own.parse(sample)
        local doc_dot = doc:dot()
        local old_dot = read("../org/dot/" .. v .. ".dot")
        if old_dot and old_dot ~= doc_dot then
            io.write("   -- changed dotfile: " .. v)
            write("../org/dot/" .. v .. "-old.dot", old_dot)
        end
        write("../org/dot/" .. v .. ".dot", doc:dot())
    end
end

local block = read("../src/grym/block.lua")
io.write(grym.invert(block))
