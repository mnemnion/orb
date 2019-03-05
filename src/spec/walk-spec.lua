


local Path = require "walk/path"
local Dir  = require "walk/directory"

local Spec = {}

Spec.folder = "walk"
Spec.it = require "kore/check"

function Spec.path()
  local a = Path "/kore/build"
  local b = a .. "/codex.orb"
  local c = a .. "/orb"
  local d = Path "/kore/build/orb"
  local a1, b1
  -- new way
  b, b1 = b: it "file-path"
     : must "have some fields"
        : have "str"
        : equalTo "/kore/build/codex.orb"
        : ofLen(#b.str)
     : must ("return the requested directory path")
        : have "idEst"
        : equalTo(Path)
        : have "parentDir"
        : calling ()
        : gives (Path "/kore/build")
        : feels()
     : must()
        : have "filename"
        : equalTo "codex.orb"
        : fin()()

  c = c : it "equals-d"
        : must ()
            : equal(d)
            : fin()()
  d = d : it "with-relpath"
      : must ()
        : have "relPath"
        : calling (Path "/core")
        : gives (Path "build/orb")
        : fin()

  a, a1 = a: it "a well-behaved Path"
             : mustnt ()
                : have "brack"
                : have "broil"
             : shouldnt()
                : have "badAttitude"
                : fin()()
end



function Spec.dir()
  a = Dir "/usr/"
         : it ("the /usr/ directory")
            : has ("exists")
            : calling()
            : gives(true)
            : has "idEst"
            : equalTo (Dir)
            : calledWith("attributes")
            : has "attr"
            : whichHas "ino"
            : fin()

  b = Dir "/imaginary-in-almost-any-conceivable-case"
         : it("imaginary directory")
             : has "exists"
              : calling()
              : should()
             : give (false)
              : fin()

   c = Dir "/usr/tmp"
          : it "swap-directory"
          : must "have basename tmp"
            : has "basename"
            : calling()
            : gives "tmp"
         : must "swap /usr for /tmp"
          : have "swapDirFor"
          : calling("/usr", "/tmp")
          : gives(Dir "/tmp/tmp")
          : fin()

end




function Spec.file()
  a = File "/orb/orb.orb"
      : it "orb-file"
      : must "have path"
        : have "path"
        : equalTo(Path "/orb/orb.orb")
        : passedTo(tostring)
        : gives("/orb/orb.orb")
      : must "give extension 'orb'"
        : calledWith "extension"
        : gives ".orb"
        : fin()
   b = File "/bin/sh"
       : it("shell")
         : has "exists"
         : calling ()
         : gives (true)
         : calledWith "extension"
         : gives ""
         : calledWith "basename"
         : gives "sh"
         : fin()
end



return function()
          Spec.path()
          Spec.dir()
          Spec.file()
          Spec:it():allReports()
       end
