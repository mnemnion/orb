local L = require "lpeg"

local Node = require "peg/node"

local m = require "grym/morphemes"

local CB = setmetatable({}, Node)

CB.__index = CB

CB.__tostring = function() return "codeblock" end

function CB.toValue(codeblock)
    codeblock.val = ""
    for _,v in ipairs(codeblock.lines) do
        codeblock.val = codeblock.val .. v .. "\n"
    end

    return codeblock.val
end

function CB.toMarkdown(codeblock)
  -- hardcode lua
  return "```lua\n"
      .. codeblock:toValue() .. "```\n"
end

function CB.dotLabel(codeblock)
    return "code block " .. tostring(codeblock.line_first)
        .. "-" .. tostring(codeblock.line_last)
end

local cb = {}

function cb.matchHead(str)
    if str ~= "" and L.match(m.codestart, str) then
        local trimmed = str:sub(L.match(m.WS * m.hax, str))
        local level = L.match(m.zaps, trimmed) - 1
        local bareline = trimmed:sub(L.match(m.zaps, trimmed))
        return true, level, bareline
    else 
        return false, 0, ""
    end
end

function cb.matchFoot(str)
    if str ~= "" and L.match(m.codefinish, str) then
        local trimmed = str:sub(L.match(m.WS * m.hax    , str))
        local level = L.match(m.fass, trimmed) - 1
        local bareline = trimmed:sub(L.match(m.fass, trimmed))
        return true, level, bareline
    else 
        return false, 0, ""
    end
end

local function new(Codeblock, level, headline, linum)
    local codeblock = setmetatable({}, CB)
    codeblock.id = "codeblock"
    codeblock.level = level
    codeblock.header = headline
    codeblock.footer = ""
    codeblock.line_first = linum
    codeblock.lines = {}

    return codeblock
end


cb.__call = new
cb.__index = cb

return setmetatable({}, cb)

