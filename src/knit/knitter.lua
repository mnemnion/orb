








































local u = require "lib/util"

local Phrase = require "espalier/phrase"

local K, k = u.inherit()
K.it = require "core/check"

















function K.knit(knitter, doc)
    local phrase = Phrase()
    local linum = 0
    for cb in doc:select("codeblock") do
        cb:check()
        if cb.lang == "lua" then
           -- Pad code with blank lines to line up errors
           local pad_count = cb.line_first - linum

           local pad = ("\n"):rep(pad_count)
           -- cat codeblock value
           phrase = phrase .. pad .. cb.val

           -- update linum
           linum = cb.line_last - 1
        else
          -- other languages
        end
    end

    return phrase, ".lua"
end

local function new(Knitter, lang)
    local knitter = setmetatable({}, K)
    knitter.lang = lang or "lua"
    return knitter
end

return u.export(k, new)
