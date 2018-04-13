












local Dir = setmetatable({}, {__index = Dir,
                isDir   = Dir})
local pl_path = require "pl.path"
local lfs = require "lfs"
local attributes = lfs.attributes
local path = require "walk/path"
local isdir  = pl_dir.isdir





function Dir.attributes(dir)
  return attributes(tostring(dir.path))
end




function new(Dir, path)
  assert(isdir(path), "fatal: " .. path .. " is not a path")
  local dir = setmetatable({}, Dir)
  dir.path = Path(str)
  return dir
end



return setmetatable({}, {__call = new, __index = Dir})
