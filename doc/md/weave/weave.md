# Weave


Our weaver is currently somewhat narrowly focused on markdown.


This will change in time.


Now to activate dot!

```lua
local L = require "lpeg"

local pl_mini = require "util/plmini"
local getfiles = pl_mini.dir.getfiles
local makepath = pl_mini.dir.makepath
local getdirectories = pl_mini.dir.getdirectories
local extension = pl_mini.path.extension
local dirname = pl_mini.path.dirname
local basename = pl_mini.path.basename
local read = pl_mini.file.read
local write = pl_mini.file.write
local isdir = pl_mini.path.isdir

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
```
```lua
function W.weaveMd(weaver, doc)
  return doc:toMarkdown()
end
```
### .dot to .svg

  Stripped down:


  - [ ] #todo add error checking here.

```lua
local popen = io.popen
local function dotToSvg(dotted, out_file)
    local success, svg_file = pcall (popen,
                          "dot -Tsvg " .. tostring(out_file), "r")
    if success then
        return svg_file:read("*a")
    else
        -- #todo start using %d and format!
        s:complain("dotError", "dot failed with " .. success)
    end
end
```
```lua
local function weave_dir(weaver, pwd, depth)
    local depth = depth + 1
    for dir_str in pl_mini.dir.walk(pwd, false, false) do
        local dir = Dir(dir_str)
        if not strHas(".git", dir.path.str)
            and not strHas("src/lib", dir.path.str) then
            dir = dir.path.str -- migrate this down
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
    for dir in pl_mini.dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir)
            and endsWith("orb", dir) then
            s:chat(a.cyan("Weave: " .. dir))
            return weave_dir(weaver, dir, 0)
        end
    end

    return false
end

W.weave_all = weave_all
```
```lua
local function new(Weaver, doc)
    local weaver = setmetatable({}, W)


    return weaver
end
```
```lua
return W
```
