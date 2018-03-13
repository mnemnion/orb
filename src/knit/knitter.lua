








































local u = require "lib/util"

local K, k = u.inherit()

















function K.knit(knitter, doc)
    local codeblocks = doc:select("codeblock")
    local phrase = ""
    local linum = 0
    for _, cb in ipairs(codeblocks) do
        cb:check()
        -- Pad code with blank lines to line up errors
        local pad_count = cb.line_first - linum

        local pad = ("\n"):rep(pad_count)
        -- cat codeblock value
        phrase = phrase .. pad .. cb.val 

        -- update linum
        linum = cb.line_last - 1
    end

    return phrase
end

local function new(Knitter, lang)
    local knitter = setmetatable({}, K)
    knitter.lang = lang or "lua"
    return knitter
end

return u.export(k, new)
