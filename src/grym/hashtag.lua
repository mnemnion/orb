-- * Hashtag module

local L = require "lpeg"

local Node = require "peg/node"
local u = require "../lib/util"

local m = require "grym/morphemes"

local H, h = u.inherit(Node)

function h.matchHashtag(line)
    local hashlen = L.match(m.hashtag, line)
    if hashlen then
        return line:sub(1,hashlen)
    else
        return nil
    end
end

local function new(Hashtag, line)
    io.write("constructing a hashtag brb\n")
    local hashtag = setmetatable({}, H)
    hashtag.id = "hashtag"
    local hashval = h.matchHashtag(line)
    if hashval then
        hashtag.val = hashval
    else
        u.freeze("Hashtag constructor did not match m.hashtag rule on:  " .. line)
    end

    return hashtag
end

return u.export(h, new)