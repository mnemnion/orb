# Hashtag module


A `#Hashtag` in Orb language is a function over the singular Orb dialect\.

Orb can be more than declarative, it can be declamatory\.  Rhetorical, even\.

One namespace must be authoritative, and it is this one\.

Here, we collect hashtags\.  In [hashline](hts://~/Orbit/hashline.orb), we
collect hash lines\.

These are operated via [orb tag](hts://~/tag/tag.orb), an inner verb on the
`codex` performed after [spinning](hts://~/walk/codex.orb)\.

\#Todo


```lua
local L = require "lpeg"

local Node = require "espalier/node"
local u = {}
function u.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end
function u.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
end

local m = require "orb:Orbit/morphemes"

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
