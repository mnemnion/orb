












local Dir = setmetatable({}, {__index = Dir})
Dir.isDir = Dir



local pl_path = require "pl.path" -- Favor lfs directly
local lfs = require "lfs"
local attributes = lfs.attributes
local Path = require "walk/path"
local isdir  = pl_path.isdir





function Dir.exists(dir)
  return isdir(dir.path.str)
end




function Dir.attributes(dir)
  return attributes(tostring(dir.path))
end




function new(Dir, path)
  local dir = setmetatable({}, {__index = Dir})
  local path_str = ""
  if path.isPath then
    assert(path.isDir, "fatal: " .. tostring(path) .. " is not a directory")
    dir.path = path
  else
    local new_path = Path(path)
    assert(new_path.isDir, "fatal: " .. tostring(path) .. " is not a directory")
    dir.path = new_path
  end
  return dir
end



return setmetatable({}, {__call = new, __index = Dir})
