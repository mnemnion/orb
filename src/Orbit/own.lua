














local L = require "lpeg"

local epeg = require "espalier/elpatt"

local Csp = epeg.Csp

local a = require "singletons/anterm"

local Node = require "espalier/node"

local m = require "Orbit/morphemes"

local Header = require "Orbit/header"
local Section = require "Orbit/section"
local Block = require "Orbit/block"
local Codeblock = require "Orbit/codeblock"

local own = {}

local blue = tostring(a.blue)
local red = tostring(a.red)
local dim = tostring(a.dim)
local green = tostring(a.green)
local cl   = tostring(a.clear)










local function lead_whitespace(str)
    local lead_ws = L.match(m.WS, str)
    if lead_ws > 1 then
        --  io.write(green..("%"):rep(lead_ws - 1)..cl)
        return lead_ws, str:sub(lead_ws)
    else
        return 0, str
    end
end









local function splitLines(str)
   local t = {}
   local function helper(line)
      table.insert(t, line)
      return ""
   end
   helper((str:gsub("(.-)\r?\n", helper)))
   return t
end
function own(doc, str)
    local linum = 1
    local doc_level = 0
    local start = 1
    local num_lines = #(splitLines(str))
    -- Track code blocks separately to avoid `* A` type collisions in code
    local code_block = false
    for _, line in ipairs(splitLines(str)) do

        -- tab and return filtration
        local l, err = line:gsub("\t", "  "):gsub("\r", "")
        local finish = start + #l
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
                    local header = Header(bareline, level, start, finish, str)

                    -- make new block and append to doc
                    doc:addSection(Section(header, linum, start, finish, doc.str),
                                      linum, start)

                else
                    doc:addLine(l, linum, finish)
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
                doc:addLine(l, linum, finish)
            end
        elseif ER then
            freeze("HUH?")
        end
        linum = linum + 1
        start = finish
        if linum < num_lines then start = start + 1 end
    end

    doc.latest.line_last = linum - 1
    doc.latest.last = start

    for sec in doc:select "section" do
        sec:check()
        sec:block()
    end
    for block in doc:select "block" do
        block:toValue()
        block:parseProse()
    end
    for sec in doc:select "section" do
        sec:weed()
    end
    for cbs in doc:select "codeblock" do
        cbs:toValue()
    end
    doc.linum = linum - 1
    return doc
end

return own
