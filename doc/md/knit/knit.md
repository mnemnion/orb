# Knit module
 

```lua
local L = require "lpeg"

local s = require "status"
local a = require "ansi"
s.chatty = true

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
local delete = pl_file.delete
local isdir = pl_path.isdir

local epeg = require "epeg"

local knitter = require "knit/knitter"

local walk = require "walk"
local strHas = walk.strHas
local endsWith = walk.endsWith
local subLastFor = walk.subLastFor
local writeOnChange = walk.writeOnChange

local Doc = require "grym/doc"

```
### knit_dir(knitter, pwd, depth)

 Walks a given directory, kniting the contents of `/org/`
 into `/src/`. 


 - [X] TODO fix up the orb/notes directory so it doesn't explode
       the knit.

```lua
local function knit_dir(knitter, orb_dir, pwd)
    local knits = {}
    for dir in pl_dir.walk(orb_dir, false, false) do
        if not strHas(".git", dir) and isdir(dir)
            and not strHas("src/lib", dir) then

            local files = getfiles(dir)
            s:chat("  * " .. dir)
            local subdirs = getdirectories(dir)
            for _, f in ipairs(files) do
                if extension(f) == ".orb" then
                    -- read and knit
                    s:verb("    - " .. f)
                    local orb_f = read(f)
                    local knitted = knitter:knit(Doc(orb_f))
                    local src_dir = subLastFor("/orb", "/src", dirname(f))
                    makepath(src_dir)
                    local bare_name = basename(f):sub(1, -5) -- 4 == #".orb"
                    local out_name = src_dir .. "/" .. bare_name .. ".lua"
                    local current_src = read(out_name) or ""
                    local changed = writeOnChange(knitted, current_src, out_name, 0)
                    if changed then
                        local tmp_dir = "../tmp" .. src_dir
                        makepath(tmp_dir)
                        local tmp_out = "../tmp" .. out_name
                        write(tmp_out, current_src)
                        knits[#knits + 1] = out_name
                    end     
                end
            end
        end
    end



    -- collect changed files if any
    local grymbacks = ""
    for _, v in ipairs(knits) do
        grymbacks = grymbacks .. v .. "\n"
    end
    if grymbacks ~= "" then
        s:chat("grymbacks: \n" .. grymbacks)
    end
    -- if nothing changes, no rollback is needed, empty file
    write(pwd .. "/.grymback", grymbacks)
    return true
end

local function knit_all(knitter, pwd)
    local did_knit = false
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir) 
            and endsWith("orb", dir) then

            s:chat(a.green("Knit: " .. dir))
            did_knit = knit_dir(knitter, dir, pwd)
        end
    end
    if not did_knit then
        s:chat("No orb directory to knit. No action taken.")
    end
    return did_knit
end

knitter.knit_all = knit_all


return knitter
```
