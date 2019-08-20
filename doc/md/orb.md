# Orb

A metalanguage for magic spells.


## Requires

Like any main entry ``orb.lua`` is mostly imports.


```lua
local ss = require "singletons"
```
### locals

```lua
local verbose = false
print ("#package.loaders: " .. #package.loaders)
```
#### Penlight excision

Nothing at all against Penlight, it's just time to start using ``luv`` and its
event loops for file interaction.


So here's a block of code we're aiming to be rid of:

```lua
local pl_mini = require "util/plmini"
local getfiles = pl_mini.dir.getfiles
local getdirectories = pl_mini.dir.getdirectories
local read = pl_mini.file.read
local write = pl_mini.file.write
local isdir = pl_mini.path.isdir
```
```lua
local ansi = ss.anterm

local knit   = require "orb/knit"
local weave  = require "orb/weave"
local compile = require "orb/compile"
local Server  = require "orb/serve"
--local Maki    = require "miki"
```
### globals

  For interactive and introspective development.


Can't wait to build a reasonable REPL.

```lua
L = require "lpeg"
u = require "util"
s = require "status"
--ss = require "singletons:singletons"
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
```
#### Sample Doc for REPLing

```lua
-- sample_doc = Doc(read("../Orb/orb.orb")) or ""

dot_sh = (require "sh"):clear_G().command('dot', '-Tsvg')
```
## Argument parsing

This is done crudely, we can use ``pl.lapp`` in future to parse within
commands to each verb.


Note here that we pass in the pwd from a shell script. This may
change, now that we've added [sh](../lib/sh.lua)

```lua
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

    orb.knit   = knit
    orb.weave  = weave

    samples = getfiles("samples")

    local own = require "Orbit/own"

    if verb == "knit" then
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
        Maki:roll()

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
```
