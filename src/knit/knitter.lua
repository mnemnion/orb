local u = require "lib/util"

local K, k = u.inherit()

function K.knit(knitter, doc)
    local codeblocks = doc:select("codeblock")
    local phrase = ""
    for _, cb in ipairs(codeblocks) do
        phrase = phrase .. cb.val .. "\n" -- a little extra ws for now

    end

    return phrase
end

local function new(Knitter, lang)
    local knitter = setmetatable({}, K)
    knitter.lang = lang or "lua"
    return knitter
end

return u.export(k, new)

