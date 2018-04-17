










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


local s = require "lib/status" ()
s.verbose = false

local m = require "Orbit/morphemes"
local walk = require "walk"
local strHas = walk.strHas
local endsWith = walk.endsWith
local subLastFor = walk.subLastFor
local writeOnChange = walk.writeOnChange
local Path = require "walk/path"
local Dir = require "walk/directory"
local File = require "walk/file"
local epeg = require "epeg"

local Doc = require "Orbit/doc"

local W, w = u.inherit()



function W.weaveMd(weaver, doc)
  return doc:toMarkdown()
end









local dot_sh = (require "sh"):clear_G().command('dot', '-Tsvg')





local function dotToSvg(dotted, out_file)
    local run_dot = dot_sh({__input = dotted})
    if run_dot.__exitcode == 0 then
        return tostring(run_dot)
    else
        s:complain(a.red("Dot returned ")
                    .. tostring(run_dot.__exitcode)
                    .. a.red(" for " .. out_file ))
        return ""
    end
end




local function weave_dir(weaver, pwd, depth)
    local depth = depth + 1
    for dir in pl_dir.walk(pwd, false, false) do
        local dirObj = Dir(dir)
        if not strHas(".git", dir) and isdir(dir)
            and not strHas("src/lib", dir) then
            dir = tostring(dir) -- migrate this down
            local files = getfiles(dir)
            s:verb(("  "):rep(depth) .. "* " .. dir)
            local subdirs = getdirectories(dir)
            for _, f in ipairs(files) do
                if extension(f) == ".orb" then
                    -- Weave and prepare out directory
                    s:verb(("  "):rep(depth) .. "  - " .. f)
                    local orb_f = read(f)
                    local doc = Doc(orb_f)
                    local doc_md_dir = subLastFor("/orb", "/doc/md", dirname(f))
                    local doc_dot_dir = subLastFor("/orb", "/doc/dot", dirname(f))
                    local doc_svg_dir = subLastFor("/orb", "/doc/svg", dirname(f))
                    makepath(doc_md_dir)
                    makepath(doc_dot_dir)
                    makepath(doc_svg_dir)
                    local bare_name = basename(f):sub(1, -5) --  == #".orb"
                    local out_md_name = doc_md_dir .. "/" .. bare_name .. ".md"
                    local out_dot_name = doc_dot_dir .. "/" .. bare_name .. ".dot"
                    local out_svg_name = doc_svg_dir .. "/" .. bare_name .. ".svg"
                    local woven_md = weaver:weaveMd(doc) or ""

                    -- Compare, report, and write out if necessary
                    local last_md = read(out_md_name) or ""
                    local changed_md = writeOnChange(woven_md, last_md, out_md_name, depth)
                    local woven_dot = doc:dot() or ""
                    local last_dot = read(out_dot_name) or ""
                    local changed_dot = writeOnChange(woven_dot, last_dot, out_dot_name, depth)

                    -- SVG call is fairly slow and only useful of the dot has changed
                    if changed_dot then
                        local woven_svg = dotToSvg(woven_dot, out_dot_name)
                        local last_svg = read(out_svg_name) or ""
                        writeOnChange(woven_svg, last_svg, out_svg_name, depth)
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
            s:chat(a.cyan("Weave: " .. dir))
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
