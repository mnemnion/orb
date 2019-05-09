












local verbose = false
local pl_file  = require "pl.file"
local pl_dir   = require "pl.dir"
local pl_path  = require "pl.path"
local getfiles = pl_dir.getfiles
local getdirectories = pl_dir.getdirectories
local read = pl_file.read
local write = pl_file.write
local isdir = pl_path.isdir

local ansi = require "ansi"

local invert = require "invert"
local knit   = require "knit"
local weave  = require "weave"
local compile = require "compile"
local Server  = require "serve"









L = require "lpeg"
u = require "util"
s = require "status"
m = require "Orbit/morphemes"
Doc = require "Orbit/doc"

Link = require "Orbit/link"

node_spec = require "espalier/spec"
Spec = require "spec/spec"
Node = require "espalier/node"
Phrase = require "espalier/phrase"

Path  = require "walk/path"
Dir   = require "walk/directory"
File  = require "walk/file"
Codex = require "walk/codex"

check = require "kore/check"






-- sample_doc = Doc(read("../Orb/orb.orb")) or ""

dot_sh = (require "sh"):clear_G().command('dot', '-Tsvg')












pwd, verb = "", ""  -- #todo make local
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
    rootCodex = Codex(Dir(pwd))

    orb.invert = invert
    orb.knit   = knit
    orb.weave  = weave

    samples = getfiles("samples")

    local own = require "Orbit/own"

    if verb == "invert" then
        -- If we allow inversion in its present no-guards state,
        -- we will lose all commentary
        u.freeze("no")
        --invert:invert_all(pwd)
    elseif verb == "knit" then
        rootCodex:spin()
        knit.knitCodex(rootCodex)
    elseif verb == "weave" then
        weave:weave_all(pwd)
    elseif verb == "spec" then
        Spec()
    elseif verb == "serve" then
        -- perform a full cycle
        rootCodex:spin()
        knit.knitCodex(rootCodex)
        compile.compileCodex(rootCodex)
        weave:weave_all(pwd)
        -- watch for changes
        rootCodex:serve()
        rootCodex.server:run()
    else
        -- do the things
        rootCodex:spin()
        knit.knitCodex(rootCodex)
        local complete, errnum, errs = compile.compileCodex(rootCodex)
        if not complete then
            print ("errors in compilation: " .. errnum)
            for i, err in ipairs(errs) do
                print("failed: " .. err)
            end
        else
            print "compiled successfully"
        end
        weave:weave_all(pwd)
    end
end

if pwd then
    _runner()
end

return orb
