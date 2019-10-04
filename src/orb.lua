










local ss = require "singletons"
local s = ss.status ()






local Orb = {}






s.verbose = true











local pl_mini = require "orb:util/plmini"
local getfiles = pl_mini.dir.getfiles
local getdirectories = pl_mini.dir.getdirectories
local read = pl_mini.file.read
local write = pl_mini.file.write
local isdir = pl_mini.path.isdir



local ansi = ss.anterm

local knit   = require "orb:knit"
local weave  = require "orb:weave/weave"
local compile = require "orb:compile"
local Server  = require "orb:serve"
local Spec    = require "orb:spec/spec"
Orb.knit, Orb.weave = knit, weave
Orb.compile, Orb.serve, Orb.spec = compile, Server, Spec









local Path  = require "orb:walk/path"
local Dir   = require "orb:walk/directory"
local File  = require "orb:walk/file"
local Codex = require "orb:walk/codex"

Orb.dir = Dir
Orb.path = Path
Orb.file = File
Orb.codex = Codex

check = require "singletons/check"






-- sample_doc = Doc(read("../Orb/orb.orb")) or ""

local sh = require "orb:util/sh":clear_G()

dot_sh = sh.command('dot', '-Tsvg')










local function _runner(pwd)
    local orb = {}

    -- The codex to be bound
    local rootCodex = Codex(Dir(pwd))

    orb.knit   = knit
    orb.weave  = weave

    --samples = getfiles("samples")

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

return Orb
