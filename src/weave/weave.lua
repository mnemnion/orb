










local L = require "lpeg"

local pl_file = require "pl.file"
local pl_dir = require "pl.dir"
local pl_path = require "pl.path"
local getfiles = pl_dir.getfiles
local makepath = pl_dir.makepath
local getdirectories = pl_dir.getdirectories
local extension = pl_path.extension
local dirname = pl_path.dirname
local basename = pl_path.basename
local read = pl_file.read
local write = pl_file.write
local isdir = pl_path.isdir

local u = require "lib/util"
local a = require "lib/ansi"


local s = require "lib/status"

local Node = require "peg/node"

local m = require "grym/morphemes"
local walk = require "walk"
local strHas = walk.strHas
local endsWith = walk.endsWith
local subLastFor = walk.subLastFor

local epeg = require "peg/epeg"

local Doc = require "grym/doc"

local W, w = u.inherit(Node)



function W.weaveMd(weaver, doc)
  return doc:toMarkdown()
end




local function weave_dir(weaver, pwd, depth)
    local depth = depth + 1
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir)
            and not strHas("src/lib", dir) then

            local files = getfiles(dir)
            s:chat(("  "):rep(depth) .. "* " .. dir)
            local subdirs = getdirectories(dir)
            for _, f in ipairs(files) do
                if extension(f) == ".orb" then
                    -- Weave and prepare out directory
                    local orb_f = read(f)
                    local doc = Doc(orb_f)
                    local woven_md = weaver:weaveMd(doc) or ""
                    local woven_dot = doc:dot()
                    local doc_md_dir = subLastFor("/orb", "/doc/md", dirname(f))
                    local doc_dot_dir = subLastFor("/orb", "/doc/dot", dirname(f))
                    makepath(doc_md_dir)
                    makepath(doc_dot_dir)
                    local bare_name = basename(f):sub(1, -5) --  == #".orb"
                    local out_md_name = doc_md_dir .. "/" .. bare_name .. ".md"
                    local out_dot_name = doc_dot_dir .. "/" .. bare_name .. ".dot"
                    -- Compare, report, and write out if necessary
                    local current_md = read(out_md_name) or ""
                    local current_dot = read(out_dot_name) or ""
                    if woven_md ~= current_md then
                        s:chat(a.green(("  "):rep(depth) .. "  - " .. out_md_name))
                        write(out_md_name, woven_md)
                    elseif current_md ~= "" and woven_md == "" then
                        s:chat(a.red(("  "):rep(depth) .. "  - " .. out_md_name))
                        delete(out_md_name)
                    else
                        s:verb(("  "):rep(depth) .. "  - " .. out_md_name)
                    end
                    if woven_dot ~= current_dot then
                        s:chat(a.green(("  "):rep(depth) .. "  - " .. out_dot_name))
                        write(out_dot_name, woven_dot)
                    elseif current_dot ~= "" and woven_dot == "" then
                        s:chat(a.red(("  "):rep(depth) .. "  - " .. out_dot_name))
                        delete(out_dot_name)
                    else
                        s:verb(("  "):rep(depth) .. "  - " .. out_dot_name)
                    end
                end
            end
        end
    end


    return true
end

local function weave_all(weaver, pwd)
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir) 
            and endsWith("orb", dir) then
            s:chat(a.green("Weave: " .. dir))
            return weave_dir(weaver, dir, 0)
        end
    end

    return false
end

W.weave_all = weave_all




local function new(Weaver, doc)
    local weaver = setmetatable({}, W)


    return weaver
end



return W
