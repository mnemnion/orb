-- Grimoire, a metalanguage for magic spells

require "pl.strict"

local verbose = false


local pl_file = require "pl.file"
local pl_dir = require "pl.dir"
local getfiles = pl_dir.getfiles
local read = pl_file.read
local write = pl_file.write

local L = require "lpeg"

local ansi = require "../lib/ansi"
local ast = require "peg/ast"
local epeg = require "peg/epeg"

local P_grym = require "grym/grymmyr" 
local m = require "grym/morphemes"

local invert = require "inverter"

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

grym.invert = invert()

local function parse(str) 
    return ast.parse(P_grym, str)
end

samples = getfiles("samples")

local own = require "grym/own"

for file in pl_dir.walk(pwd, false, false) do
    if file:sub(1,4) ~= ".git" then
        io.write(file.. "\n")
    end
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

local block = read("../src/grym/block.lua")
local invert_block = grym.invert(block)

-- io.write(invert_block)
