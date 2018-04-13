












local Dir = {}
Dir.isDir = Dir

local __Dirs = {} -- Cache to keep each Dir unique by Path



local pl_path = require "pl.path" -- Favor lfs directly
local lfs = require "lfs"
local attributes = lfs.attributes
local Path = require "walk/path"
local isdir  = pl_path.isdir
local mkdir = lfs.mkdir





function Dir.exists(dir)
  return isdir(dir.path.str)
end



function Dir.mkdir(dir)
  if dir:exists() then
    return false
  else
    local success, msg, code = mkdir(dir.path.str)
    if success then
      return success
    else
      code = tostring(code)
      s:complain("mkdir failure # " .. code, msg, dir)
      return false
    end
  end
end




function Dir.attributes(dir)
  return attributes(dir.path.str)
end




function new(__, path)
  if __Dirs[path] then
    return __Dirs[path]
  end
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
  __Dirs[path] = dir

  return dir
end



return setmetatable({}, {__call = new, __index = Dir})
