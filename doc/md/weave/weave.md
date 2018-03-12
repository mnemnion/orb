# Weave


```lua
local L = require "lpeg"

local u = require "lib/util"

local Node = require "peg/node"

local m = require "grym/morphemes"

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

local epeg = require "peg/epeg"

local Doc = require "grym/doc"

local W, w = u.inherit(Node)
```
```lua
local function strHas(substr, str)
    return L.match(epeg.anyP(substr), str)
end

local function endsWith(substr, str)
    return L.match(L.P(string.reverse(substr)),
        string.reverse(str))
end
```
```lua
local function subLastFor(match, swap, str)
    local trs, hctam = string.reverse(str), string.reverse(match)
    local first, last = strHas(hctam, trs)
    if last then
        -- There is some way to do this without reversing the string twice,
        -- but I can't be arsed to find it. ONE BASED INDEXES ARE A MISTAKE
        return string.reverse(trs:sub(1, first - 1) 
            .. string.reverse(swap) .. trs:sub(last, -1))
    else
        u.freeze("didn't find an instance of " .. match .. " in string: " .. str)
    end 
end
```
```lua
function W.weaveMd(weaver, doc)
  return doc:toMarkdown()
end
```
```lua
local function weave_dir(weaver, pwd, depth)
    local depth = depth + 1
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir)
            and not strHas("src/lib", dir) then

            local files = getfiles(dir)
            io.write(("  "):rep(depth) .. "* " .. dir .. "\n")
            local subdirs = getdirectories(dir)
            for _, f in ipairs(files) do
                if extension(f) == ".gm" then
                    local doc_dir = dirname(subLastFor("/orb", "/doc/md", f))
                    makepath(doc_dir)
                    local bare_name = basename(f):sub(1, -4) -- 3 == #".gm"
                    local out_name = doc_dir .. "/" .. bare_name .. ".md"
                    io.write(("  "):rep(depth) .. "  - " .. out_name .. "\n")
                    write(out_name, weaver:weaveMd(Doc(read(f))))

                end
            end
            for _, d in ipairs(subdirs) do
                weave_dir(weaver, d, depth)
            end
        end
    end

    return true
end

local function weave_all(weaver, pwd)
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir) 
            and endsWith("orb", dir) then

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
