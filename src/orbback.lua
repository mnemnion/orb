













local L = require "lpeg"

local s = require "lib/status"
local u = require "lib/util"
local a = require "lib/ansi"
s.chatty = true

local epeg = require "epeg"

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

local walk = "walk"





local pwd = ""

if (arg) then
  pwd = table.remove(arg, 1)
else
  os.exit("Must be called with a root codex directory", 1)
end

io.write("pwd: " .. pwd .. "\n")

local orbback_rc = read(pwd .. "/.orbback")
if not orbback_rc then
  s:chat("No contents in orbback.  No action taken.")
  os.exit()
else
  for _,v in ipairs(epeg.split(orbback_rc, "\n")) do
    if v ~= "" then
      s:chat("Reverting " .. a.cyan(orbback_rc))
      s:chat("Reading " .. a.green(pwd .. "/tmp" .. v))
      local new_tmp = read(pwd .. "/tmp" .. v)
      if new_tmp then
        s:chat("  - writing")
        write(v, read(pwd .. "/tmp" .. v))
      end
    end
  end
end
