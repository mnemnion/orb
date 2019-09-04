










local ss = require "singletons"
local s = ss.status ()






local Orb = {}






s.verbose = true
s:verb ("#package.loaders: " .. #package.loaders)











local pl_mini = require "util/plmini"
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
--local Maki    = require "miki"









L = require "lpeg"
--ss = require "singletons:singletons"
m = require "orb:Orbit/morphemes"
Doc = require "orb:Orbit/doc"

Link = require "orb:Orbit/link"

--node_spec = require "espalier/spec"
--Spec = require "spec/spec"
Node = require "espalier/node"
Phrase = require "singletons/phrase"

Path  = require "orb:walk/path"
Dir   = require "walk/directory"
File  = require "orb:walk/file"
Codex = require "orb:walk/codex"

check = require "singletons/check"






-- sample_doc = Doc(read("../Orb/orb.orb")) or ""

local sh = require "util/sh":clear_G()

dot_sh = sh.command('dot', '-Tsvg')










local pwd, verb = sh.command("pwd")(), ""

s:verb ("pwd:::: " .. tostring(pwd))

if arg then
    pwd = table.remove(arg, 1)
    verb = table.remove(arg, 1)
    for _, v in ipairs(arg) do
        io.write(ansi.yellow(v).."\n")
    end
end

local function _runner()
    local orb = {}

    -- The codex to be bound
    local rootCodex = Codex(Dir(pwd))

    orb.knit   = knit
    orb.weave  = weave

    --samples = getfiles("samples")

    local own = require "Orbit/own"

    if verb == "knit" then
        rootCodex:spin()
        knit.knitCodex(rootCodex)
    elseif verb == "weave" then
        weave:weaveCodex(rootCodex)
    elseif verb == "spec" then
        Spec()
    elseif verb == "serve" then
        -- perform a full cycle
        rootCodex:spin()
        knit.knitCodex(rootCodex)
        compile.compileCodex(rootCodex)
        weave:weaveCodex(rootCodex)
        -- watch for changes
        rootCodex:serve()
        rootCodex.server:run()
        Maki:roll()

    else
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
end

local uv = require "luv"

if pwd then
    print "orbing"
    _runner()
end

return Orb
