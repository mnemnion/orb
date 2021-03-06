# Hashtag module


A ``#Hashtag`` in Orb language is a function over the singular Orb dialect.


Orb can be more than declarative, it can be declamatory.  Rhetorical, even.


One namespace must be authoritative, and it is this one.


Here, we collect hashtags.  In [hashline](hts://~/Orbit/hashline.orb), we
collect hash lines.

```lua
local L = require "lpeg"

local Node = require "espalier/node"
local u = require "../lib/util"

local m = require "Orbit/morphemes"

local H, h = u.inherit(Node)

function h.matchHashtag(line)
    local hashlen = L.match(L.C(m.hashtag), line)
    if hashlen then
        return hashlen
    else
        return ""
        -- This is what it /should/ do, but
        -- u.freeze("Hashtag constructor did not match m.hashtag rule on:  " .. line)
    end
end

local function new(Hashtag, line)
    local hashtag = setmetatable({}, H)
    hashtag.id = "hashtag"
    hashtag.val = h.matchHashtag(line):sub(2, -1)

    return hashtag
end

return u.export(h, new)
```
