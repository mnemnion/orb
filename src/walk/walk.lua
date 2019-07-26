







local L = require "lpeg"

local s = require "status"
local u = require "util"
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



local Walk = {}
Walk.Path = require "walk/path"
Walk.Dir  = require "walk/directory"
Walk.File = require "walk/file"
Walk.Codex = require "walk/codex"
Walk.writeOnChange = require "walk/ops"



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



return Walk
