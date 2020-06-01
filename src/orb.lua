











core = require "core:core"








local ss = require "singletons"
local s = ss.status ()






local Orb = {}






s.verbose = true











local knit   = require "orb:knit"
local weave  = require "orb:weave/weave"
local compile = require "orb:compile"

local Codex = require "orb:walk/codex"
local Spec    = require "orb:spec/spec"
Orb.knit, Orb.weave = knit, weave
Orb.compile, Orb.spec = compile, Spec









local Path  = require "fs:fs/path"
local Dir   = require "fs:fs/directory"
local File  = require "fs:fs/file"

Orb.dir = Dir
Orb.path = Path
Orb.file = File
Orb.codex = Codex

local check = require "singletons/check"









local sh = require "orb:util/sh"

local dot_sh = sh.command('dot', '-Tsvg')









local Lume = require "orb:lume/lume"
Orb.lume = Lume












local function _runner(pwd)
    local orb = {}
    -- The codex to be bound
    local rootCodex = Codex(Dir(pwd))

    orb.knit   = knit
    orb.weave  = weave
    local own = require "orb:Orbit/own"
    -- do the things
    rootCodex:spin()
    knit.knitCodex(rootCodex)
    local complete, errnum, errs = compile.compileCodex(rootCodex)
    if not complete then
        s:verb ("errors in compilation: " .. errnum)
        for i, err in ipairs(errs) do
            s:verb("failed: " .. err)
        end
    else
        s:verb "compiled successfully"
    end
    weave:weaveCodex(rootCodex)
end

Orb.run = _runner

core = nil

return Orb
