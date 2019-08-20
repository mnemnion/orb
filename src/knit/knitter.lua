




























local u = {}

-- A helper function which takes an optional metatable,
-- returning a meta-ed table and a table meta-ed from
-- that.
-- The former can be filled with methods and the latter
-- made into a constructor with __call, as well as a
-- convenient place to put library functions which aren't
-- methods/self calls.
--
-- - meta: a base metatable
--
-- - returns:
--   - The class metatable
--   - Constructor and library table
--
function u.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end

-- Function to export modules
--
-- The first argument of util.inherit being filled with methods,
-- the second argument is passed to util.export as =mod=, along
-- with a function =constructor= which will serve to create a
-- new instance.
--
function u.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
end

local Phrase = require "singletons/phrase"

local K, k = u.inherit()
K.it = require "singletons/check"

















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
