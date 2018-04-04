











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

local P_grym = require "grym/grymmyr" 

local invert = require "invert"
local knit   = require "knit"
local weave  = require "weave"

local ast  = require "peg/ast"
local epeg = require "peg/epeg"












L = require "lpeg"
u = require "util"
s = require "status"
m = require "grym/morphemes"
Doc = require "grym/doc"

Link = require "grym/link"

spec = require "node/spec"
pnf = require "node/define"
Node = require "node/node"









sample_doc = Doc(read("../orb/grym.orb")) or ""

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
elseif verb == "spec" then
    -- This is just a shim to get us inside whatever
    -- I'm working on
    local abstr = "((first second) third (fourth fifth 23))"
    local abNode = spec.clu(abstr)
    assert(abNode.isNode)
    io.write(tostring(abNode))
    io.write(tostring(abNode:dot()))
    io.write("nodewalker:\n")
    for node in abNode:walkDeep() do
        io.write(node.id .. " -- ")
    end
    io.write("\n")
    for node in abNode:walk() do
        io.write(node.id .. " ~~ ")
    end
    io.write("\n")
    for node in abNode:select("atom") do
        io.write(node.id .. " %% ")
    end
    io.write("\n")
    for tok in abNode:tokens() do
        io.write(tok .. " || ")
    end
    io.write("\n\n"..ansi.cyan("DOC SEQUENCE").."\n")
    io.write("type of sample_doc.select is " .. type(sample_doc.select) .. "\n")
    -- wacky metatable surgery
    setmetatable(getmetatable(sample_doc), Node)
    for sec in sample_doc:select("section") do
        io.write(ansi.magenta("section") .. "\n")
        io.write(tostring(sec) .. "\n")
    end
    for cb in sample_doc:select("codeblock") do
        io.write(ansi.yellow "codeblock" .. "\n")
        io.write(cb:toValue().. "\n")
    end

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
