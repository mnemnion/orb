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

local epeg = require "peg/epeg"

local knitter = require "knit/knitter"

local walk = require "walk"
local strHas = walk.strHas
local endsWith = walk.endsWith
local subLastFor = walk.subLastFor

local Doc = require "grym/doc"


local function knit_dir(knitter, pwd)
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir)
            and not strHas("src/lib", dir) then

            local files = getfiles(dir)
            s:chat("  * " .. dir)
            local subdirs = getdirectories(dir)
            for _, f in ipairs(files) do
                if extension(f) == ".orb" then
                    -- read and knit
                    local orb_f = read(f)
                    local knitted = knitter:knit(Doc(orb_f))
                    local src_dir = dirname(subLastFor("/orb", "/src", f))
                    makepath(src_dir)
                    local bare_name = basename(f):sub(1, -5) -- 4 == #".orb"
                    local out_name = src_dir .. "/" .. bare_name .. ".lua"
                    local current_src = read(out_name) or ""

                    if knitted ~= "" then    
                        if knitted ~= current_src then
                            s:chat(a.green("    - " .. out_name))
                            write(out_name, knitted)

                        else
                            s:verb("    - " .. out_name)
                        end
                    elseif current_src ~= "" then
                        s:chat(a.red("    - " .. out_name))
                        delete(out_name)
                    end
                end
            end
        end
    end

    return true
end

local function knit_all(knitter, pwd)
    local did_knit = false
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir) 
            and endsWith("orb", dir) then

            s:chat(a.green("Knit: " .. dir))
            did_knit = knit_dir(knitter, dir)
        end
    end
    if not did_knit then
        s:chat("No orb directory to knit. No action taken.")
    end
    return did_knit
end

knitter.knit_all = knit_all


return knitter

