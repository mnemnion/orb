# Knit module 

```lua
local L = require "lpeg"

local pl_file = require "pl.file"
local pl_dir = require "pl.dir"
local pl_path = require "pl.path"
local getfiles = pl_dir.getfiles
local getdirectories = pl_dir.getdirectories
local makepath = pl_dir.makepath
local extension = pl_path.extension
local dirname = pl_path.dirname
local basename = pl_path.basename
local read = pl_file.read
local write = pl_file.write
local isdir = pl_path.isdir

local epeg = require "peg/epeg"

local knitter = require "knit/knitter"

local Doc = require "grym/doc"

local function strHas(substr, str)
    return L.match(epeg.anyP(substr), str)
end

local function endsWith(substr, str)
    return L.match(L.P(string.reverse(substr)),
        string.reverse(str))
end
```
 Finds the last match for a literal substring and replaces it
 with =swap=, returning the new string.


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
 Walks a given directory, kniting the contents of =/org/=
 into =/src/=. 

 - [ ] TODO fix up the orb/notes directory so it doesn't explode
       the knit.
 

```lua
local function knit_dir(knitter, pwd, depth)
    local depth = depth + 1
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir)
            and not strHas("src/lib", dir)
            and not strHas("orb/notes", dir) then

            local files = getfiles(dir)
            io.write(("  "):rep(depth) .. "* " .. dir .. "\n")
            local subdirs = getdirectories(dir)
            for _, f in ipairs(files) do
                if extension(f) == ".gm" then
                    -- move it to orb file
                    local bare_name = f:sub(1, -4)
                    local orb_name = bare_name .. ".orb"
                    movefile(f, orb_name)
                elseif extension(f) == ".orb" then
                    local src_dir = dirname(subLastFor("/orb", "/src", f))
                    makepath(src_dir)
                    local bare_name = basename(f):sub(1, -5) -- 4 == #".orb"
                    local out_name = src_dir .. "/" .. bare_name .. ".lua"
                    io.write(("  "):rep(depth) .. "  - " .. out_name .. "\n")
                    local knitted = knitter:knit(Doc(read(f)))
                    if knitted ~= "" then
                        write(out_name, knitter:knit(Doc(read(f))))
                    end
                end
            end
            for _, d in ipairs(subdirs) do
                knit_dir(knitter, d, depth)
            end
        end
    end
    return true
end

local function knit_all(knitter, pwd)
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir) 
            and endsWith("orb", dir) then

            return knit_dir(knitter, dir, 0)
        end
    end
    return false
end

knitter.knit_all = knit_all


return knitter
```
