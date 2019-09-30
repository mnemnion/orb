


































local L = require "lpeg"

local Node = require "espalier/node"

local m = require "orb:Orbit/morphemes"

local CB = setmetatable({}, Node)
CB.id = "codeblock"

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
  local lang = codeblock.lang or "orbdefault"
  return "```" .. lang .. "\n"
         .. codeblock:toValue() .. "```\n"
end

function CB.dotLabel(codeblock)
    return "code block " .. tostring(codeblock.line_first)
        .. "-" .. tostring(codeblock.line_last)
end

local cb = {}





function CB.check(codeblock)
  assert(codeblock.line_first)
  assert(codeblock.line_last)
end














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
    codeblock.level = level
    codeblock.header = headline
    codeblock.lang = L.match(L.C(m.symbol), headline) or ""
    codeblock.footer = ""
    codeblock.line_first = linum
    codeblock.lines = {}

    return codeblock
end


cb.__call = new
cb.__index = cb

return setmetatable({}, cb)
