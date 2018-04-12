# Orbback


  This is a standalone program to restore orb in the event that a knit
results in an unusable orb module.


The plan: A ``.orb`` file in the root directory will contain any
knit-modified files from the last pass.  ``orb`` itself will read and write
to the .orb file, maintaining a data structure in the meantime; this will
be in Lua-native table format, at first, eventually Clu(den).

### includes

```lua
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
```
```lua

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
```
