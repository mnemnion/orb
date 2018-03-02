-- * Block module
--
--   A Block is the container for the next level of granularity below
-- a Section. Any Section has a Header and one or more Blocks. Both the
-- Header and the Block may be virtual, that is, without contents.
--
-- The most general premise is that Blocks are delineated by blank line
-- whitespace. 
--
-- A paragraph of prose is the simplest block, and the default.  A list with
-- a tag line is a block also, as is a table.  Most importantly for our short
-- path, code blocks are enclosed in blocks as well.
--
-- Blocking needs to identify when it has structure, and when prose, on a 
-- line-by-line basis.  It must also apply the cling rule to make sure that
-- e.g. tags are part of the block indicated by whitespacing. 
-- 
-- Blocking need not, and mostly should not, parse within structure or prose.
-- These categories are determined by the beginning of a line, making this
-- tractable. 
-- 
-- The cling rule requires lookahead. LPEG is quite capable of this, as is 
-- packrat PEG parsing generally.  In the bootstrap implementation, we will
-- parse once for ownership, again (in the `lines` array of each Section) for
-- blocking, and a final time to parse within blocks. 
--
-- Grimoire is intended to work, in linear time, as a single-pass PEG
-- grammar.  Presently (Feb 2018) I'm intending to prototype that with 
-- PEGylator and port it to `hammer` with a `quipu` back-end. 
--

local L = require "lpeg"

local Node = require "peg/node"
local Codeblock = require "grym/codeblock"

local m = require "grym/morphemes"
local util = require "../lib/util"
local freeze = util.freeze


-- Metatable for Blocks

local B = setmetatable({}, { __index = Node })
B.__index = B

B.__tostring = function(block) 
    return "Block"
end

function B.addLine(block, line)
    block.lines[#block.lines + 1] = line
    return block
end

-- Adds a .val field which is the union of all lines.
-- Useful in visualization. 
function B.toValue(block)
    block.val = ""
    for _,v in ipairs(block.lines) do
        block.val = block.val .. v .. "\n"
    end
end

function B.dotLabel(block)
    return "block " .. tostring(block.line_first) 
        .. "-" .. tostring(block.line_last)
end


-- Constructor/module

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


-- Sorts lines into structure and prose.
-- 
-- - line : taken from block.lines
--
-- - returns: 
--        1. true for structure, false for prose
--        2. id of structure line or "" for prose
--
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

local function isTagline(line)
    return L.match(m.tagline_p, line)
end

-- Count the forward blank lines
-- - lines: the full lines array of the section
-- - linum: current index into lines
--
-- - returns: number of blank lines forward of index
--
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


-- Blocks a Section.
--
-- This is a moderately complex state machine, which
-- works on a line-by-line basis with some lookahead.
--
-- First off, we have a Header at [1], and may have one or 
-- more Sections The blocks go between the Header and the remaining
-- Sections, so we have to lift them and append after blocking.
-- 
-- Next, we parse the lines, thus:
--
-- Prose line: if preceded by at least one blank line,
-- make a new block, otherwise append to existing block.
--
-- List line: new block unless previous line is also list,
-- in which case append. 
--
-- Table line: same as list.
--
-- Tag line: a tag needs to cling, so we need to check the
-- number of blank lines before and after a tag line, if any.
-- If even, a tag line clings down.
--
-- Code block: These actually must be guarded against in the 
-- first pass, because code structured like a header line has 
-- to be assigned to a code block, not introduce a spurious 
-- header. 
-- 
-- This is itself tricky because, to fulfill our promise of an
-- error-free format, we need to react to unbalanced documents,
-- in which a `#!` has no matching `#/`.  In this case the leading
-- `#!` line is simple prose and we must re-parse the rest of the
-- document accordingly. 
-- 
-- This isn't a routine we want to code twice, so bad code fences need
-- to be pre-treated to escape further attention. 
--
-- - #params
--   - section: the Section to be blocked
--
-- returns: the same Section, filled in with blocks
--
function b.block(section)
    -- There is always a header at [1], though it may be nil
    -- If there are other Nodes, they are sections and must be appended
    -- after the blocks.
    local sub_sections = {}
    for i = 2, #section do
        sub_sections[#sub_sections + 1] = section[i]
        section[i] = nil
    end

    -- Every section gets at least one block, at [2], which may be empty.
    local latest = new(nil, nil, section.line_first) -- current block
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
                        latest = new(nil, nil, inset)
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
                        latest = new(nil, l, inset)
                        section[#section + 1] = latest
                        back_blanks = 0
                    end                        
                else
                    if back_blanks > 0 and lead_blanks == false then
                        if not tagging then
                        -- new block
                            latest.line_last = inset - 1
                            latest = new(nil, l, inset)
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
                io.write("code footer encountered \n")
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
    latest.line_last = section.line_last

    -- Append sections, if any, which follow our blocks
    for _, v in ipairs(sub_sections) do
        section[#section + 1] = v
    end
    return section
end

b["__call"] = new
b["__index"] = b

return setmetatable({}, b)









