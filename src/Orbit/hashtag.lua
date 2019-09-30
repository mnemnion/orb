


















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
