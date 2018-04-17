# Knit module


 This is due for a complete overhaul.

```lua
local L = require "lpeg"

local s = require "status" ()
local a = require "ansi"
s.chatty = true
s.verbose = false

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


local knitter = require "knit/knitter"

local walk = require "walk"
local Dir, Path, File = walk.Dir, walk.Path, walk.File
local strHas = walk.strHas
local endsWith = walk.endsWith
local subLastFor = walk.subLastFor
local writeOnChange = walk.writeOnChange

local Doc = require "Orbit/doc"

```
### knit_dir(knitter, pwd, depth)

 Walks a given directory, kniting the contents of ``/org/``
 into ``/src/``.


 - [X] TODO fix up the orb/notes directory so it doesn't explode
       the knit.

```lua
local function knit_dir(knitter, orb_dir, pwd)
    local knits = {}
    local srcDir = orb_dir:parentDir() .. "/src"
    assert(srcDir.idEst == Dir)
    s:chat("Sorcery directory: " .. tostring(srcDir))
    for dir in pl_dir.walk(orb_dir.path.str, false, false) do
        local file_strs = getfiles(dir)
        local dirObj = Dir(dir)
        local files  = dirObj:getfiles()
        s:chat("  * " .. a.yellow(dir))
        for _, file in ipairs(files) do
            f = file.path.str
            local ext = file:extension()
            if ext == ".orb" then
                -- read and knit
                s:chat("    - " .. tostring(file))
                local orb_str = file:read()
                local knitted = knitter:knit(Doc(orb_str))
                local src_dir = subLastFor("/orb", "/src", dirname(f))
                makepath(src_dir)
                local bare_name = basename(f):sub(1, - (#ext + 1)) -- 4 == #".orb"
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

    -- collect changed files if any
    local orbbacks = ""
    for _, v in ipairs(knits) do
        orbbacks = orbbacks .. v .. "\n"
    end
    if orbbacks ~= "" then
        s:chat("orbbacks: \n" .. orbbacks)
    end
    -- if nothing changes, no rollback is needed, empty file
    write(tostring(pwd) .. "/.orbback", orbbacks)
    return true
end

```

- [ ] #todo add some proper codex detection and correction


## knit_all(knitter, pwd_str)

Both sides of the interface to this are wrong, but let's build
the Dir locally and go from there.


``knitter`` isn't wrong externally, the internal interface it
presents needs considerable refinement to work correctly.

```lua

local function knit_all(knitter, pwd_str)
    local did_knit = false
    local pwd = Dir(pwd_str)
    pwd.codex_type = "base"
    s:chat("pwd:" .. tostring(pwd))
    local orbDir = pwd .. "/orb"
    s:chat("orbDir: " .. tostring(orbDir))
    if orbDir:exists() then
        s:chat(a.cyan("Knit: ") .. tostring(orbDir))
        orbDir.codex_type = "home"
        did_knit = knit_dir(knitter, orbDir, pwd)
    else
        s:chat("No orb directory to knit. No action taken.")
        return false
    end
    return did_knit
end

knitter.knit_all = knit_all


return knitter
```
