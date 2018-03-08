-- * Ownership function
--
--    Taking a multi-pass approach to this Grimoire instance will benefit us 
-- in a few ways. 
--
--    First, Grimoire itself is structured in a certain fashion. The 
-- straightforward thing is to mirror that fashion in code.
--
--    Second, the critical path right now is simple code generation from 
-- Grimoire documents. Parsing prose gets useful later, for now I simply
-- wish to unravel some existing code into Grimoire format and start working
-- on it accordingly. 

local L = require "lpeg"

local epeg = require "peg/epeg"

local util = require "../lib/util"
local freeze = util.freeze

local Csp = epeg.Csp

local a = require "../lib/ansi"
local u = require "lib/util"


local ast = require "peg/ast"

local Node = require "peg/node"

local m = require "grym/morphemes"

local Header = require "grym/header"
local Section = require "grym/section"
local Block = require "grym/block"
local Codeblock = require "grym/codeblock"

local own = {}

local blue = tostring(a.blue)
local red = tostring(a.red)
local dim = tostring(a.dim)
local green = tostring(a.green)
local cl   = tostring(a.clear)

-- *** Helper functions for own.parse

-- Trims leading whitespace, returning the amount taken and
-- the trimmed string.
-- 
local function lead_whitespace(str)
    local lead_ws = L.match(m.WS, str)
    if lead_ws > 1 then
        --  io.write(green..("%"):rep(lead_ws - 1)..cl)
        return lead_ws, str:sub(lead_ws)
    else
        return 0, str
    end
end


-- Takes a string, parsing ownership.
-- Returns a Doc.
--
function own(doc, str)
    local linum = 1
    local doc_level = 0
    local start = 1
    local num_lines = #(epeg.split(str,"\n"))

    for _, line in ipairs(epeg.split(str, "\n")) do
        local finish = start + #line
        -- tab and return filtration
        local l, err = line:gsub("\t", "  "):gsub("\r", "") 
        -- Track code blocks separately to avoid `* A` type collisions in code
        local code_block = false
        -- We should always have a string but..
        if l then
            if not code_block then
                local indent, l_trim = lead_whitespace(l)
                local code_head = Codeblock.matchHead(l)
                if code_head then 
                    code_block = true 
                end
                local isHeader, level, bareline = Header.match(l_trim) 

                if isHeader then              
                    local header = Header(bareline, level, start, finish, doc)

                    -- make new block and append to doc
                    doc:addSection(Section(header, linum), linum)

                else 
                    doc:addLine(l, linum)
                end
            else 
                -- code block logic, including restarts
                --
                -- NOTE that this will choke on unmatched code headers,
                -- which I intend to fix. But it's fiddly.
                local code_foot = Codeblock.matchFoot(l)
                if code_foot then 
                    code_block = false
                end
                doc:addLine(l, linum)
            end
        elseif ER then
            freeze("HUH?")
        end
        linum = linum + 1
        start = finish
        if linum < num_lines then start = start + 1 end
    end
    if (doc.latest) then
        doc.latest.line_last = linum - 1
    end
    local sections = doc:select("section")
    for _, s in ipairs(sections) do
        s:check()
        s:block()
    end
    local blocks = doc:select("block")
    for _, v in ipairs(blocks) do
        v:toValue()
    end
    local cbs = doc:select("codeblock")
    for _, v in ipairs(cbs) do
        v:toValue()
    end
    doc.linum = linum - 1
    return doc
end

return own