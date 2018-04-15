











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












L = require "lpeg"
u = require "util"
s = require "status"
m = require "Orbit/morphemes"
Doc = require "Orbit/doc"

Link = require "Orbit/link"

node_spec = require "node/spec"
Spec = require "spec/spec"
Node = require "node/node"
Path = require "walk/path"
Dir  = require "walk/directory"
check = require "core/check"









sample_doc = Doc(read("../Orb/orb.orb")) or ""

dot_sh = (require "sh"):clear_G().command('dot', '-Tsvg')











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
    knit:knit_all(pwd)
elseif verb == "weave" then
    weave:weave_all(pwd)
elseif verb == "spec" then
    Spec()

elseif not verb then
    -- do the things
    weave:weave_all(pwd)
    knit:knit_all(pwd)
end






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
