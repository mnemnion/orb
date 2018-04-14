


local Path = require "walk/path"
local Dir  = require "walk/directory"

local Spec = {}

Spec.folder = "walk"

function Spec.path()
  local a = Path "/core/build/"
  local b = a .. "codex.orb"
  local c = a .. "/bar/"
  local a1, b1
  -- new way
  b, b1 = b: it("a file Path")
     : must("have some fields")
        : have "str"
        : equalTo "/core/build/codex.orb"
        : ofLen(#b.str)
        -- : should()
        : have "isPath"
        : equalTo(Path) -- it does not
        : report()

  a, a1 = a: it("a well-behaved Path")
             : mustnt()
                : have "brack"
                : have "broil"
                : have "badAttitude"
                : report()
end



function Spec.dir()
  a = Dir "/usr/" : it ("the /usr/ directory")
         : has ("exists")
         : calling()
         : gives(true)
         : report ()
end

return function()
          Spec.path()
          Spec.dir()
       end
