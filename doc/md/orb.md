# Orb

A metalanguage for magic spells.


## Requires

Like any main entry ``orb.lua`` is mostly imports.


```lua
local ss = require "singletons"
local s = ss.status ()
```
### Orb

```lua
local Orb = {}
```
### locals

```lua
s.verbose = true
```
#### Penlight excision

Nothing at all against Penlight, it's just time to start using ``luv`` and its
event loops for file interaction.


So here's a block of code we're aiming to be rid of:

```lua
local pl_mini = require "orb:util/plmini"
local getfiles = pl_mini.dir.getfiles
local getdirectories = pl_mini.dir.getdirectories
local read = pl_mini.file.read
local write = pl_mini.file.write
local isdir = pl_mini.path.isdir
```
```lua
local knit   = require "orb:knit"
local weave  = require "orb:weave/weave"
local compile = require "orb:compile"
local Spec    = require "orb:spec/spec"
Orb.knit, Orb.weave = knit, weave
Orb.compile, Orb.spec = compile, Spec
```
```lua
local Path  = require "orb:walk/path"
local Dir   = require "orb:walk/directory"
local File  = require "orb:walk/file"
local Codex = require "orb:walk/codex"

Orb.dir = Dir
Orb.path = Path
Orb.file = File
Orb.codex = Codex

local check = require "singletons/check"
```
#### Dot command

```lua
local sh = require "orb:util/sh"

dot_sh = sh.command('dot', '-Tsvg')
```
## Argument parsing

This is in the process of being replaced with an in-bridge invocation.

```lua
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

return Orb
```
