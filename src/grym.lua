-- Grimoire, a metalanguage for magic spells

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
local m      = require "grym/morphemes"

local invert = require "invert"
local knit   = require "knit"

-- Argument parsing goes here

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

local function parse(str) 
    return ast.parse(P_grym, str)
end

samples = getfiles("samples")

local own = require "grym/own"

if verb == "invert" then
    invert:invert_all(pwd)
elseif verb == "knit" then
    -- knitter goes here
    --knit:knit_all(pwd)
    ---[[
    local nodestr = read("peg/epeg.lua")
    local owned_node = own.parse(nodestr)
    io.write(tostring(owned_node))
    io.write(knit:knit(owned_node))
    --]]
end


-- Run the samples and make dotfiles
---[[
for _,v in ipairs(samples) do
    if v:match("~") == nil then
        if verbose then io.write(v) end
        local sample = read(v)
        --io.write(v.."\n")
        local doc = own.parse(sample)
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

