
local L = require "lpeg"

local pl_file = require "pl.file"
local pl_dir = require "pl.dir"
local pl_path = require "pl.path"
local getfiles = pl_dir.getfiles
local getdirectories = pl_dir.getdirectories
local extension = pl_path.extension
local read = pl_file.read
local write = pl_file.write
local isdir = pl_path.isdir

local epeg = require "peg/epeg"

local inverter = require "invert/inverter"

local lua_inv = inverter("lua")

local function strHas(substr, str)
    return L.match(epeg.anyP(substr), str)
end

local function endsWith(substr, str)
    return L.match(L.P(string.reverse(substr)),
        string.reverse(str))
end


-- Walks a given directory, inverting the contents of =/src/=
-- into =/org/=. 
-- 
local function invert_dir(pwd, depth)
    local depth = depth + 1
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir)
            and not strHas("src/lib", dir) then

            local files = getfiles(dir)
            io.write(("  "):rep(depth) .. "* " .. dir .. "\n")
            local subdirs = getdirectories(dir)
            for _, f in ipairs(files) do
                if (lua_inv.extension == extension(f)) then
                    io.write(("  "):rep(depth) .. "  - " .. f .. "\n")
                end
            end
            for _, d in ipairs(subdirs) do
                invert_dir(d, depth)
            end
        end
    end
end

local function invert_all(pwd)
    for dir in pl_dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir) then
            if endsWith("src", dir) then
                return invert_dir(dir, 0)
            end
        end
    end
    return false
end


return { invert = lua_inv,
         inverter = inverter, 
         invert_dir = invert_all }