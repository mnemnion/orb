







local L = require "lpeg"

local s = require "singletons/status" ()
local a = require "singletons/anterm"
s.chatty = true

local pl_mini = require "orb:util/plmini"
local pl_mini = require "orb:util/plmini"
local read, write, delete = pl_mini.file.read,
                            pl_mini.file.write,
                            pl_mini.file.delete
local getfiles = pl_mini.dir.getfiles
local getdirectories = pl_mini.dir.getdirectories
local makepath = pl_mini.dir.makepath
local extension = pl_mini.path.extension
local dirname = pl_mini.path.dirname
local basename = pl_mini.path.basename
local isdir = pl_mini.path.isdir

local epeg = require "orb:util/epeg"



local Walk = {}
Walk.Path = require "fs:path"
Walk.Dir  = require "fs:directory"
Walk.File = require "fs:file"
Walk.Codex = require "orb:walk/codex"
Walk.writeOnChange = require "orb:walk/ops"



function Walk.strHas(substr, str)
    return L.match(epeg.anyP(substr), str)
end

function Walk.endsWith(substr, str)
    return L.match(L.P(string.reverse(substr)),
        string.reverse(str))
end







function Walk.subLastFor(match, swap, str)
   local trs, hctam = string.reverse(str), string.reverse(match)
   local first, last = Walk.strHas(hctam, trs)
   if last then
      -- There is some way to do this without reversing the string twice,
      -- but I can't be arsed to find it. ONE BASED INDEXES ARE A MISTAKE
      return string.reverse(trs:sub(1, first - 1)
          .. string.reverse(swap) .. trs:sub(last, -1))
   else
      s:halt("didn't find an instance of " .. match .. " in string: " .. str)
   end
end



function Walk.writeOnChange(out_file, newest)
    newest = tostring(newest)
    out_file = tostring(out_file)
    local current = read(tostring(out_file))
    -- If the text has changed, write it
    if newest ~= current then
        s:chat(a.green("  - " .. tostring(out_file)))
        write(out_file, newest)
        return true
    -- If the new text is blank, delete the old file
    elseif current ~= "" and newest == "" then
        s:chat(a.red("  - " .. tostring(out_file)))
        delete(out_file)
        return false
    else
    -- Otherwise do nothing

        return nil
    end
end




return Walk
