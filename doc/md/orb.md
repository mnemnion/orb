# Grimoire

A metalanguage for magic spells.

## Requires

Like any main entry ``grym.lua`` is mostly imports.


### locals

```lua
require "pl.strict"



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

local epeg = require "epeg"


```
### globals

  For interactive and introspective development.


Can't wait to build a reasonable REPL.

```lua
L = require "lpeg"
u = require "util"
s = require "status"
m = require "Orbit/morphemes"
Doc = require "Orbit/doc"

Link = require "Orbit/link"

spec = require "node/spec"
Node = require "node/node"
Path = require "walk/path"
```
#### Sample Doc for REPLing

  I'm going to add a [link here](http://example.com), to have something
to work with.

```lua
sample_doc = Doc(read("../Orb/orb.orb")) or ""

dot_sh = (require "sh"):clear_G().command('dot', '-Tsvg')
```
## Argument parsing

This is done crudely, we can use ``pl.lapp`` in future to parse within
commands to each verb.


Note here that we pass in the pwd from a shell script. This may
change, now that we've added [sh](../lib/sh.lua)]]

```lua
local pwd, verb = "", ""

if (arg) then
    pwd = table.remove(arg, 1)
    verb = table.remove(arg, 1)
    for _, v in ipairs(arg) do
        io.write(ansi.yellow(v).."\n")
    end
end


local grym = {}

grym.invert = invert
grym.knit   = knit
grym.weave  = weave

samples = getfiles("samples")

local own = require "Orbit/own"

if verb == "invert" then
    -- If we allow inversion in its present no-guards state,
    -- we will lose all commentary
    u.freeze("no")
    --invert:invert_all(pwd)
elseif verb == "knit" then
    -- knitter goes here
    knit:knit_all(pwd)
elseif verb == "weave" then
    -- local weaved = weave:weaveMd(Doc(read("../orb/grym/block.gm")))
    -- io.write(weaved)
    weave:weave_all(pwd)
elseif verb == "spec" then
    -- This is just a shim to get us inside whatever
    -- I'm working on
    local abstr = "((first second) third (fourth fifth 23))"
    local abNode = spec.clu(abstr)
    assert(abNode.isNode)
    io.write(tostring(abNode))
    io.write("nodewalker:\n")
    for node in abNode:walkPost() do
        io.write(node.id .. " -- ")
    end
    io.write("\n")
    for node in abNode:walk() do
        io.write(node.id .. " ~~ ")
    end
    io.write("\n")
    for node in abNode:select("atom") do
        io.write(node.id .. " %% ")
        if second then
            io.write(" found a second " .. second .. " ")
        end
    end
    io.write("\n")
    for tok in abNode:tokens() do
        io.write(tok .. " || ")
    end
    if s.verbose then
        io.write("\n\n"..ansi.cyan("DOC SEQUENCE").."\n")
        for sec in sample_doc:select("section") do
            io.write(ansi.magenta("section") .. "\n")
            io.write(tostring(sec) .. "\n")
        end
        local sects = sample_doc:gather "section"
        for _, sec in ipairs(sects) do
            io.write(ansi.cyan("section") .. "\n")
            io.write(tostring(sec) .. "\n")
        end
    end

elseif not verb then
    -- do the things
    weave:weave_all(pwd)
    knit:knit_all(pwd)
end
```
### Run the samples and make dotfiles

```lua
---[[
for _,v in ipairs(samples) do
    if v:match("~") == nil then
        if verbose then io.write(v) end
        local sample = read(v)
        --io.write(v.."\n")
        local doc = Doc(sample)
        local doc_dot = doc:dot()
        local old_dot = read("../orb/dot/" .. v .. ".dot")
        if old_dot and old_dot ~= doc_dot then
            io.write("   -- changed dotfile: " .. v)
            write("../orb/dot/" .. v .. "-old.dot", old_dot)
        end
        write("../orb/dot/" .. v .. ".dot", doc:dot())
    end
end
--]]
```
