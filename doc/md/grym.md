# Grimoire 
A metalanguage for magic spells.

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

local L = require "lpeg"

local ansi = require "lib/ansi"
local u    = require "lib/util"

local ast  = require "peg/ast"
local epeg = require "peg/epeg"

local P_grym = require "grym/grymmyr" 
local m = require "grym/morphemes"
local Doc = require "grym/doc"

local invert = require "invert"
local knit   = require "knit"
local weave  = require "weave"
```
 Argument parsing goes here

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
grym.knit = knit

samples = getfiles("samples")

local own = require "grym/own"

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

end
```
 Run the samples and make dotfiles

```lua
---[[
for _,v in ipairs(samples) do
    if v:match("~") == nil then
        if verbose then io.write(v) end
        local sample = read(v)
        --io.write(v.."\n")
        local doc = Doc(sample)
        local doc_dot = doc:dot()
        local old_dot = read("../org/dot/" .. v .. ".dot")
        if old_dot and old_dot ~= doc_dot then
            io.write("   -- changed dotfile: " .. v)
            write("../org/dot/" .. v .. "-old.dot", old_dot)
        end
        write("../org/dot/" .. v .. ".dot", doc:dot())
    end
end
--]]
```