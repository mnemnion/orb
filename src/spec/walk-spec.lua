


local Path = require "walk/path"
local Dir  = require "walk/path"

local Spec = {}

Spec.folder = "walk"

function Spec.path()
  local a = new(_, "/core/build/")
  local b = clone(a) .. "codex.orb"
  local c = a .. "bar/"
  local a1, b1
  -- new way
  b, b1 = b: it("a file Path")
     : must("have some fields")
        : have "str"
        : equalTo "/core/build/codex.orb"
        : ofLen(12)
        : have "isPath"
        : equalTo(Path)
        : report()

  a, a1 = a: it(): mustnt()
     : have "brack"
     : have "broil"
     : have "badAttitude"
     : report()
end
